#! /bin/bash

################################################################################
##
## Bash script that decodes the binary event list and runs apply_gti.py
##
##
## Written by Abigail Stevens, A.L.Stevens@uva.nl, 2014-2015
################################################################################

########################################
## Make sure the input arguments are ok
########################################

if (( $# != 3 )); then
    echo -e "\t\tUsage: ./good_events.sh <prefix> <obs ID list> <list of GTI'd event lists to write to>\n"
    exit
fi

prefix=$1
obsID_list=$2
gtideventlist_list=$3

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


if [ -e "$gtideventlist_list" ]; then rm "$gtideventlist_list"; fi; touch "$gtideventlist_list"

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
				echo "$gtid_eventlist"
				echo "$gtid_eventlist" >> $gtideventlist_list
			else
				echo -e "\tNo good events in this eventlist. Deleting."	
				rm "$gtid_eventlist"
			fi  ## End of 'if there are good events in this eventlist'
		else
			echo -e "\tERROR: apply_gti.py did not work. GTI'd eventlist does not exist."
		fi  ## End of 'if gti'd eventlist exists, i.e. apply_gti worked.
		
	fi  ## End of 'if there are event files in this obsID directory'
	
done  ## End of looping through obsIDs in obsID_list


################################################################################
## All done!
if [ -e dump.txt ]; then rm dump.txt; fi
echo "'Good events' script is finished."
################################################################################
