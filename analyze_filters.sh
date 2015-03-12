#!/bin/bash

################################################################################
## 
## Analyzes filter files from multiple obsIDs to show which pcus are on when.
## 
## Something_list could be either an obsID list or a list of filter files, but
## it must be internally consistent.
## 
## Written by Abigail Stevens, A.L.Stevens at uva.nl, 2015
## 
################################################################################

## Make sure the input arguments are ok
if (( $# != 5 )); then
    echo -e "\t\tUsage: ./analyze_filters.sh <script dir> <list dir> <out dir> \
<prefix> <list of either obsIDs or filter files>\n"
    exit
fi

analyzefilters_args=( "$@" )
script_dir="${analyzefilters_args[0]}"
list_dir="${analyzefilters_args[1]}"
out_dir="${analyzefilters_args[2]}"
prefix="${analyzefilters_args[3]}"
something_list="${analyzefilters_args[4]}"

################################################################################

filter_tab="$out_dir/${prefix}_filters.dat"
if [ -e "$filter_tab" ]; then rm "$filter_tab"; fi; touch "$filter_tab"

################################################################################
################################################################################

test_line=$(head -n 1 "$something_list")
# echo "$test_line"
len_test_line=${#test_line}
# echo "$len_test_line"

## If: the list is of obsIDs
if (( $len_test_line == 14 )); then

	obsID_list="$something_list"
	filter_list="${out_dir}/tmp_filters.txt"
	if [ -e "$filter_list" ]; then rm "$filter_list"; fi; touch "$filter_list"
	
	## Looping through obsIDs
	for obsID in $( cat "$obsID_list" ) ; do
			
		filter_file="$out_dir/$obsID"/filter.xfl

		if [ ! -e "$filter_file" ]; then
			echo -e "\tERROR: Filter file for $obsID does not exist."
			continue
		fi
		echo "$filter_file" >> $filter_list
		
	done

## Else if: the list is of filter files (check extension)
elif (( $len_test_line > 14 )); then

	extension=$(echo "$test_line" | tail -c 5)
	
	if [ "$extension" == ".xfl" ]; then
		filter_list="$something_list"
	else
		echo -e "\tERROR: List contents not recognized. Exiting."
		exit
	fi
	
## Else: contents not recognized.
else
	echo -e "\tERROR: List contents not recognized. Exiting."
	exit
fi

####################################################
## Run the python script pcu_filter.py to plot pcus
####################################################

echo python ./pcu_filter.py "$filter_list" "$prefix" "$out_dir"
python "$script_dir"/pcu_filter.py "$filter_list" "$prefix" "$out_dir"
		
# if [ -e "$out_dir/${prefix}_pcus_on.png" ]; then open "$out_dir/${prefix}_pcus_on.png"; fi
# if [ -e "$out_dir/${prefix}_filter_info.txt" ]; then open "$out_dir/${prefix}_filter_info.txt"; fi

################################################################################
## All done!
################################################################################
