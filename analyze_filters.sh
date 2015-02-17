#!/bin/bash

################################################################################
## 
## Analyzes filter files from multiple obsIDs to show which pcus are on when.
## 
## Written by Abigail Stevens, A.L.Stevens@uva.nl, 2015
## 
################################################################################

## Make sure the input arguments are ok
# if (( $# != 2 )); then
#     echo -e "\t\tUsage: ./analyze_filters.sh <obs ID list> <filename prefix>\n"
#     exit
# fi
# obslist=$1
# prefix=$2

obslist="/Users/abigailstevens/Dropbox/Lists/GX339-BQPO_obsIDs.lst" 
prefix="GX339-BQPO"

################################################################################

## If heainit isn't running, start it
if (( $(echo $DYLD_LIBRARY_PATH | grep heasoft | wc -l) < 1 )); then
	. $HEADAS/headas-init.sh
fi

home_dir=$(ls -d ~)  ## The home directory of this machine
list_dir="$home_dir/Dropbox/Lists"
# red_dir="$home_dir/Reduced_data/${prefix}"
red_dir="$home_dir/Dropbox/Research/sample_data"
script_dir="$home_dir/Dropbox/Research/rxte_reduce"
filter_tab="$red_dir/filters.dat"
if [ -e "$filter_tab" ]; then rm "$filter_tab"; fi; touch "$filter_tab"
filter_list="${red_dir}/tmp_filters.txt"
if [ -e "$filter_list" ]; then rm "$filter_list"; fi; touch "$filter_list"

################################################################################

# for line in $( cat "$propID_list" ); do
# 
# 	IFS=',' read -a array <<< "$line"
# 	propID="${array[1]}"
# 	
# 	obslist="$list_dir/${propID}_obsIDs.lst"
# 	if [ ! -e "$obslist" ]; then
# 		obslist="$list_dir/${propID}_dl_obsIDs.txt"
# 		
# 		if [ ! -e "$obslist" ]; then 
# 			echo -e "\tERROR: obsID list not found for $propID."
# 			continue
# 		fi
# 	fi
	
	##########################################
	## Loop over all PCA index files (ObsIDs)
	##########################################
	
	for obsid in $( cat "$obslist" ) ; do
		
		# if [ ! -d "$red_dir/$obsid" ]; then
# 			echo -e "\tERROR: Reduced directory for $obsid does not exist."
# 			continue
# 		fi
# 		
# 		filter_file="$red_dir/$obsid"/filter.xfl
		filter_file="$home_dir/Dropbox/Research/sample_data/${obsid}_filter.xfl"
# 		echo "$filter_file"

		if [ ! -e "$filter_file" ]; then
			echo -e "\tERROR: Filter file for $obsid does not exist."
			continue
		fi
		
		echo "$filter_file" >> $filter_list
		
	done
	
# done

python "$script_dir"/pcu_filter.py "$filter_list"
		

# open "$filter_tab"

################################################################################
