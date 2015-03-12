#! /bin/bash

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
## Notes: HEASOFT 6.14 (or higher), bash 3.* and Python 2.7.* (with supporting 
##		  libraries) must be installed in order to run this script.
## 
## Written by Abigail Stevens, A.L.Stevens@uva.nl, 2014-2015
## 
################################################################################

########################################
## Make sure the input arguments are ok
########################################

if (( $# != 3 )); then
    echo -e "\t\tUsage: ./good_events.sh <prefix> <obs ID list> <list of GTI'd \
event lists to write to>\n"
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

removed_obsIDs="$list_dir/$prefix_obsIDs_removed.lst"

if [ -e "$gtideventlist_list" ]; then rm "$gtideventlist_list"; fi; touch "$gtideventlist_list"
if [ -e "$removed_obsIDs" ]; then rm "$removed_obsIDs"; fi; touch "$removed_obsIDs"

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
			
		done  ## End of looping through the eventlists in this obsID
		
		##################################################################
		## Merging multiple orbits from one obsID into a single eventlist
		##################################################################
		
		merged_eventlist="$data_dir/eventlist.fits"
		orbits_list="${data_dir}/multi_evts.lst"
		
		if (( num_files > 1 )); then
			echo "Multiple orbits per obsID. Merging eventlists."
			ls "$data_dir"/eventlist_*.fits > $orbits_list
			fmerge infiles=@"$orbits_list" \
				outfile="$merged_eventlist" \
				columns=- \
				copyprime=yes \
				lastkey='TSTOP DATE-END TIME-END'  \
				clobber=yes
		else  ## If there's only one file, just copy it
			cp "${eventlist}" "${merged_eventlist}"
		fi

		gtid_eventlist="$data_dir/GTId_eventlist.fits"
	# 	gtid_eventlist="$data_dir/GTId_eventlist.dat"
	
		####################
		## Run apply_gti.py
		####################
		
		if [ -e "$eventlist" ] && [ -e "$gtifile" ]; then
			python "$exe_dir/apply_gti.py" "$merged_eventlist" "$gtifile" "$gtid_eventlist"
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
			else
				echo -e "\tNo good events in eventlist for $obsID. Deleting."	
				echo "$obsID" >> "$removed_obsIDs"

				echo "$data_dir"
# 				rm -rf "$data_dir"

			fi  ## End of 'if there are good events in this eventlist'
		else
			echo -e "\tERROR: apply_gti.py did not work. GTI'd eventlist does not exist."
		fi  ## End of 'if gti'd eventlist exists, i.e. apply_gti worked.
		
	fi  ## End of 'if there are event files in this obsID directory'
	
done  ## End of looping through obsIDs in obsID_list

## If there were obsIDs that had no good events, remove it from the list.
if (( $(wc -l < $removed_obsIDs) > 0 )); then
	python -c "import tools; tools.remove_obsIDs('$obsID_list', '$removed_obsIDs')"
	echo -e "\n\nNeed to re-run reduce_alltogether.sh. Check run.log for full \
command.\n\n"
fi

################################################################################
## All done!
if [ -e dump.txt ]; then rm dump.txt; fi
echo "'Good events' script is finished."
################################################################################
