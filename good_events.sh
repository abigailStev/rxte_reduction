#!/bin/bash

################################################################################
##
## Bash script that decodes the binary event list and runs apply_gti.py
##
## If there are some events that don't have any good events in them, they are 
## removed from lists and the user is instructed to run reduce_alltogether.sh 
## again. The reduce_alltogether.sh call that was run before can be found in 
## ./run.log. Note that I'm unsure how well this and rxte_reduce_data handle 
## one orbit having good events and another one not.
##
## WARNING: This script deletes a directory if that obsID has no good events
## in it (~line 147). Uncomment the 'echo' line and comment the 'rm' line to 
## check what will be deleted. Be sure it's ok to erase it!
## 
## Notes: HEASOFT 6.21.*, bash 3.*, and conda 4.0.7+ with python 2.7.*
## 		  must be installed in order to run this script.
## 
## Written by Abigail Stevens, A.L.Stevens at uva.nl, 2014-2017
## 
################################################################################

########################################
## Make sure the input arguments are ok
########################################

if (( $# != 3 )); then
    echo -e "\tUsage: ./good_events.sh <prefix> <obs ID list> <list of " \
            "GTI'd event lists to write to>\n"
    exit
fi

goodevents_args=( "$@" )

prefix="${goodevents_args[0]}"
obsID_list="${goodevents_args[1]}"
gtideventlist_list="${goodevents_args[2]}"

################################################################################

######################################
## If heainit isn't running, start it
######################################

if (( $(echo $DYLD_LIBRARY_PATH | grep heasoft | wc -l) < 1 )); then
	. $HEADAS/headas-init.sh
fi

home_dir=$(ls -d ~)
exe_dir="$home_dir/Dropbox/Research/rxte_reduce"
red_dir="$home_dir/Reduced_data/$prefix"
list_dir="$home_dir/Dropbox/Lists"

bad_orbits="$red_dir/bad_orbits.lst"  ## list of obsIDs with at least one orbit
                                      ## with no good events

if [ -e "$gtideventlist_list" ]; then rm "$gtideventlist_list"; fi
touch "$gtideventlist_list"
if [ -e "$bad_orbits" ]; then rm "$bad_orbits"; fi; touch "$bad_orbits"

################################################################################
################################################################################

############################################
## Looping through the obsIDs in obsID_list
############################################
for obsID in $( cat "$obsID_list" ); do

	data_dir="$red_dir/$obsID"
	gtifile="$data_dir/gti_file.gti"
	num_files=$( ls "$data_dir/evt"_*.pca | wc -l )

	####################################################
	## If there are event files to decode in this obsID
	####################################################

	if (( num_files > 0 )); then

		#######################################################
		## Looping through the different event files per obsID
		#######################################################

		for (( num=1;num<=num_files;++num )); do

			binaryfile="$data_dir/evt_${num}.pca"
			eventlist="$data_dir/eventlist_${num}.fits"
			if [ -e "$eventlist" ]; then rm "$eventlist"; fi

			##################################
			## 'Decode' the binary event list
			##################################

			if [ -e "$binaryfile" ]; then
				decodeevt infile="$binaryfile" outfile="$eventlist" > dump.txt
			else
				echo -e "\tBinary file not decoded; does not exist."
				continue
			fi

			gtid_eventlist="$data_dir/GTId_eventlist_${num}.fits"

			####################
            ## Run apply_gti.py
            ####################

            if [ -e "${eventlist}" ] && [ -e "$gtifile" ]; then
                python "$exe_dir/apply_gti.py" "${eventlist}" "$gtifile" \
                        "$gtid_eventlist"
#                rm "${eventlist}"
            else
                continue
            fi

            if [ -e "$gtid_eventlist" ]; then
                naxis2=$( python -c "from tools import get_key_val; print get_key_val('$gtid_eventlist', 1, 'NAXIS2')" )

                ###############################################################
                ## Only append the GTI'd eventlist file name to the list if it
                ## has good events in it (i.e. length > 0)
                ###############################################################

                if (( $naxis2 > 0 )); then
                    echo "$gtid_eventlist" >> $gtideventlist_list
                    echo "$obsID" >> "$bad_orbits"
                else
                    echo -e "\tNo good events in eventlist for $obsID orbit ${num}."
                    rm "$binaryfile"
                    echo "$obsID" >> "$bad_orbits"
                fi  ## End of 'if there are good events in this eventlist'
            else
                echo -e "\tERROR: apply_gti.py did not work. GTI'd eventlist "\
                        "does not exist."
            fi  ## End of 'if gti'd eventlist exists, i.e. apply_gti worked.
		done  ## End of looping through the eventlists in this obsID

	fi  ## End of 'if there are event files in this obsID directory'

done  ## End of looping through obsIDs in obsID_list

## If there were obsIDs that had orbits no good events, check if no good orbits
if (( $( wc -l < $bad_orbits ) > 0 )); then
    python -c "from tools import no_duplicates; no_duplicates('$bad_orbits')"

    for obsID in $( cat "$bad_orbits" ); do

        cd "$red_dir/$obsID"
        ## If there were no good orbits in an obsID, delete it
        if (( $(ls -1 GTId_eventlist* | cat | wc -l) == 0 )); then

            cd ..
            echo "No good orbits for $obsID. Deleting."
            rm -rf "$red_dir/$obsID"

            filter_list="${red_dir}/all_filters.lst"
            evt_bkgd_list="${red_dir}/all_event_bkgd.lst"
            se_list="${red_dir}/all_evt.lst"
            sa_list="${red_dir}/all_std2.lst"

            awk "!/$obsID/" $obsID_list > dump.txt && mv dump.txt $obsID_list
            awk "!/$obsID/" $filter_list > dump.txt && mv dump.txt $filter_list
            awk "!/$obsID/" $evt_bkgd_list > dump.txt && mv dump.txt $evt_bkgd_list
            awk "!/$obsID/" $se_list > dump.txt && mv dump.txt $se_list
            awk "!/$obsID/" $sa_list > dump.txt && mv dump.txt $sa_list

            echo -e "\n\nNeed to re-run reduce_alltogether.sh. Check run.log "\
                    "and/or progress.log for full command.\n\n"
        fi
    done

fi

################################################################################
## All done!
if [ -e dump.txt ]; then rm dump.txt; fi
echo "'Good events' script is finished."
################################################################################
