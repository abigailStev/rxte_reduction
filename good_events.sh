#! /bin/bash

## Make sure the input arguments are ok
if (( $# != 3 )); then
    echo -e "\t\tUsage: ./good_events.sh <prefix> <obs ID list> <GTI'd event list>"
    exit
fi

## If heainit isn't running, start it
if (( $(echo $DYLD_LIBRARY_PATH | grep heasoft | wc -l) < 1 )); then
	. $HEADAS/headas-init.sh
fi

prefix=$1
obsID_list=$2
# echo "$obsID_list"
gtideventlist_list=$3

home_dir=$(ls -d ~)  # the -d flag is extremely important here

if [ -e "$gtideventlist_list" ]; then rm "$gtideventlist_list"; fi; touch "$gtideventlist_list"

for obsID in $(cat $obsID_list); do
# 	echo "obsID: $obsID"
	dir="$home_dir/Reduced_data/$prefix/$obsID"
	gtifile="$dir/gti_file.gti"
	end_num=`ls "$dir/evt"_*.pca | wc -l`
		
# 	echo "Number of files for this obsID: $end_num"
	if ((end_num>0)); then
		for ((num=1;num<=end_num;++num)); do
			binaryfile="$dir/evt_${num}.pca"
			eventlist="$dir/eventlist_${num}.fits"
			gtid_eventlist="$dir/GTId_eventlist_${num}.fits"
# 			gtid_eventlist="$dir/GTId_eventlist_${num}.dat"
			
			if [ -e "$eventlist" ]; then
				rm "$eventlist"
			fi
			
			if [ -e "$binaryfile" ]; then
				decodeevt infile="$binaryfile" outfile="$eventlist"
			fi
	
# 			if [ ! -e "$gtid_eventlist" ] && [ -e "$eventlist" ] && [ -e "$gtifile" ]; then
			if [ -e "$eventlist" ] && [ -e "$gtifile" ]; then
# 				echo "Applying GTI file"
				python "$home_dir/Dropbox/Research/rxte_reduce/apply_gti.py" "$eventlist" "$gtifile" "$gtid_eventlist"
			fi

			if [ -e "$gtid_eventlist" ]; then
				naxis2=$( python -c "from tools import get_key_val; print get_key_val('$gtid_eventlist', 1, 'NAXIS2')" )
# 				echo "$naxis2"
				if (( $naxis2 > 0 )); then
					echo "$gtid_eventlist" >> $gtideventlist_list
				else
					echo "No good events in this event list."	
					rm "$gtid_eventlist"
				fi
			fi
		done
	fi
done

open "$gtideventlist_list"
echo "'Good events' script is finished."
