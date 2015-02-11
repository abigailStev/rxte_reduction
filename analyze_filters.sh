#!/bin/bash

###############################################################################
##
##
##
## 
###############################################################################

## Make sure the input arguments are ok
if (( $# != 2 )); then
    echo -e "\t\tUsage: ./analyze_filters.sh <obs ID list> <filename prefix>"
    exit
fi
obslist=$1
prefix=$2


###############################################################################

## If heainit isn't running, start it
if (( $(echo $DYLD_LIBRARY_PATH | grep heasoft | wc -l) < 1 )); then
	. $HEADAS/headas-init.sh
fi


home_dir=$(ls -d ~)  ## The home directory of this machine
list_dir="$home_dir/Dropbox/Lists"
red_dir="$home_dir/Reduced_data/${prefix}"
filter_tab="$red_dir/filters.dat"
if [ -e "$filter_tab" ]; then rm "$filter_tab"; fi; touch "$filter_tab"

###############################################################################

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
		
		if [ ! -d "$red_dir/$obsid" ]; then
			echo -e "\tERROR: Reduced directory for $obsid does not exist."
			continue
		fi
		
		filter_file="$red_dir/$obsid"/filter.xfl
# 		echo "$filter_file"

		if [ ! -e "$filter_file" ]; then
			echo -e "\tERROR: Filter file for $obsid does not exist."
			continue
		fi
		## For plotting the filter file:
# 		filter_plot="$red_dir/$obsid"_filter.eps
# 		if [ -e "$filter_plot" ]; then rm "$filter_plot"; fi
# 		fplot "$filter_file"[1] TIME "num_pcu_on pcu0_on pcu1_on pcu2_on pcu3_on pcu4_on offset elv" - /xw "hardcopy ${filter_plot}/cps"
# 		echo "$filter_plot"
		
		python -c "from tools import pcu_info; pcu_info('$filter_file', '$filter_tab')"
				
	done
	
# done

# open "$filter_tab"

###############################################################################
