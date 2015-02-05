#! /bin/bash

###############################################################################
##
## Bash script that decodes the binary event list and runs apply_gti.py
##
##
## Written by Abigail Stevens, A.L.Stevens@uva.nl, 2014-2015
###############################################################################

## Make sure the input arguments are ok
if (( $# != 3 )); then
    echo -e "\t\tUsage: ./good_events.sh <prefix> <obs ID list> <GTI'd event list to write to>"
    exit
fi

prefix=$1
obsID_list=$2
gtideventlist_list=$3

## If heainit isn't running, start it
if (( $(echo $DYLD_LIBRARY_PATH | grep heasoft | wc -l) < 1 )); then
	. $HEADAS/headas-init.sh
fi

home_dir=$(ls -d ~)
exe_dir="$home_dir/Dropbox/Research/rxte_reduce"
red_dir="$home_dir/Reduced_data/$prefix/

if [ -e "$gtideventlist_list" ]; then rm "$gtideventlist_list"; fi; touch "$gtideventlist_list"

############################################
## Looping through the obsIDs in obsID_list
############################################
for obsID in $( cat "$obsID_list" ); do

	data_dir="$red_dir/$obsID"
	gtifile="$data_dir/gti_file.gti"
	num_files=`ls "$data_dir/evt"_*.pca | wc -l`
		
# 	echo "Number of files for this obsID: $num_files"
	if (( num_files>0 )); then
		for (( num=1;num<=num_files;++num )); do
		
			binaryfile="$data_dir/evt_${num}.pca"
			eventlist="$data_dir/eventlist_${num}.fits"
			gtid_eventlist="$data_dir/GTId_eventlist_${num}.fits"
# 			gtid_eventlist="$data_dir/GTId_eventlist_${num}.dat"
			
			if [ -e "$eventlist" ]; then rm "$eventlist"; fi
			
			##################################
			## 'Decode' the binary event list
			##################################
			
			if [ -e "$binaryfile" ]; then
				decodeevt infile="$binaryfile" outfile="$eventlist"
			else
				echo -e "\tBinary file not decoded; does not exist."
				continue
			fi
			
			####################
			## Run apply_gti.py
			####################
			
			if [ -e "$eventlist" ] && [ -e "$gtifile" ]; then
				python "$exe_dir/apply_gti.py" "$eventlist" "$gtifile" "$gtid_eventlist"
			else
				continue
			fi

			if [ -e "$gtid_eventlist" ]; then
				naxis2=$( python -c "from tools import get_key_val; print get_key_val('$gtid_eventlist', 1, 'NAXIS2')" )
				
				## Only append the GTI'd eventlist file name to the list if it 
				## has good events in it (i.e. length > 0)
				if (( $naxis2 > 0 )); then
					echo "$gtid_eventlist" >> $gtideventlist_list
				else
					echo "No good events in this event list."	
					rm "$gtid_eventlist"
				fi  ## End of 'if there are good events in this eventlist'
				
			fi  ## End of 'if gti'd eventlist exists, i.e. apply_gti worked.
			
		done  ## End of looping through the eventlists in this obsID
	fi  ## End of 'if there are event files in this obsID directory'
	
done  ## End of looping through obsIDs in obsID_list


###############################################################################
## All done!

echo "'Good events' script is finished."
###############################################################################
