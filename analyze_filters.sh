#!/bin/bash

################################################################################
## 
## Analyzes filter files from multiple obsIDs to show which pcus are on when.
## 
## Written by Abigail Stevens, A.L.Stevens at uva.nl, 2015
## 
################################################################################

## Make sure the input arguments are ok
if (( $# != 5 )); then
    echo -e "\t\tUsage: ./analyze_filters.sh <script dir> <list dir> <out dir> \
<prefix> <obsID list>\n"
    exit
fi

analyzefilters_args=( "$@" )
script_dir="${analyzefilters_args[0]}"
list_dir="${analyzefilters_args[1]}"
out_dir="${analyzefilters_args[2]}"
prefix="${analyzefilters_args[3]}"
obsID_list="${analyzefilters_args[4]}"

################################################################################

## If heainit isn't running, start it
if (( $(echo $DYLD_LIBRARY_PATH | grep heasoft | wc -l) < 1 )); then
	. $HEADAS/headas-init.sh
fi

filter_tab="$out_dir/filters.dat"
filter_list="${out_dir}/tmp_filters.txt"

if [ -e "$filter_tab" ]; then rm "$filter_tab"; fi; touch "$filter_tab"
if [ -e "$filter_list" ]; then rm "$filter_list"; fi; touch "$filter_list"

################################################################################
################################################################################

# for line in $( cat "$propID_list" ); do
# 
# 	IFS=',' read -a array <<< "$line"
# 	propID="${array[1]}"
# 	
# 	obsID_list="$list_dir/${propID}_obsIDs.lst"
# 	if [ ! -e "$obsID_list" ]; then
# 		obsID_list="$list_dir/${propID}_dl_obsIDs.txt"
# 		
# 		if [ ! -e "$obsID_list" ]; then 
# 			echo -e "\tERROR: obsID list not found for $propID."
# 			continue
# 		fi
# 	fi
	
	########################
	## Loop over all ObsIDs
	########################
	
	for obsID in $( cat "$obsID_list" ) ; do
		
		# if [ ! -d "$out_dir/$obsID" ]; then
# 			echo -e "\tERROR: Reduced directory for $obsID does not exist."
# 			continue
# 		fi
# 		
		filter_file="$out_dir/$obsID"/filter.xfl
# 		filter_file="$home_dir/Dropbox/Research/sample_data/${obsID}_filter.xfl"
# 		echo "$filter_file"

		if [ ! -e "$filter_file" ]; then
			echo -e "\tERROR: Filter file for $obsID does not exist."
			continue
		fi
		
		echo "$filter_file" >> $filter_list
		
	done
	
# done

####################################################
## Run the python script pcu_filter.py to plot pcus
####################################################
echo python ./pcu_filter.py "$filter_list" "$prefix" "$out_dir"
python "$script_dir"/pcu_filter.py "$filter_list" "$prefix" "$out_dir"
		
if [ -e "$out_dir/pcus_on.png" ]; then open "$out_dir/pcus_on.png"; fi
# if [ -e "$out_dir/filter_info.txt" ]; then open "$out_dir/filter_info.txt"; fi

## All done!
################################################################################
