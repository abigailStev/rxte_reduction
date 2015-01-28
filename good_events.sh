#! /bin/bash

home_dir=$(ls -d ~)  # the -d flag is extremely important here

propID=$1
obsID_list=$2
# echo "$obsID_list"
event_list=$3

if [ -e "$event_list" ]; then
	rm "$event_list"
fi
touch "$event_list"

for obsID in $(cat $obsID_list); do
# 	echo "obsID: $obsID"
	dir="$home_dir/Reduced_data/$propID/$obsID"
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
				echo "$gtid_eventlist" >> $event_list
			fi
		done
	fi
done

echo "'Good events' script is finished."
