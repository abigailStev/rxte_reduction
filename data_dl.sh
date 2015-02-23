#!/bin/bash

################################################################################
##
## Downloads raw data directories from the RXTE remote archives.
## Requires a list of proposal IDs with the archive prefix, and for each
## proposal ID a corresponding list of obsIDs to download.
##
## Usage: ./data_dl.sh <proposal_ID_list>
##
## Written by Abigail Stevens, A.L.Stevens@uva.nl, 2013-2015
## 
################################################################################

## Make sure the input arguments are ok
if (( $# != 1 )); then
    echo -e "\t\tUsage: ./data_dl.sh <proposal ID list>"
    exit
fi

propID_list=$1

home_dir=$(ls -d ~)
list_dir="$home_dir/Dropbox/Lists"
data_dir_prefix="$home_dir/Data/RXTE"  ## Saves data as data_dir_prefix/propID/obsID
dl_log="$home_dir/Dropbox/Research/rxte_reduce/download.log"
obsID_list_suffix="dl_obsIDs.txt"  ## obsID list, that you already should have 
	## made per propID, is list_dir/propID_{obsID_list_suffix}
web_prefix="ftp://legacy.gsfc.nasa.gov/xte/data/archive"  ## Don't change this.

################################################################################
################################################################################

if [ ! -e "$propID_list" ]; then
	echo -e "\tERROR: proposal ID list does not exist. Exiting."
	exit
fi

if [ -e "$dl_log" ]; then rm "$dl_log"; fi

####################################
## Looping through each proposal ID
####################################

for line in $( cat "$propID_list" ); do
	
	IFS=',' read -a array <<< "$line"
	archive_prefix="${array[0]}"	
	propID="${array[1]}"
	
	echo "Proposal ID: $propID"
	
	data_dir="${data_dir_prefix}/$propID"
	obsID_list="$list_dir/${propID}_${obsID_list_suffix}"
	dl_list="$list_dir/${propID}_downloads.txt"
	web_archive="${web_prefix}/${archive_prefix}/$propID"
	
	if [ -e "$dl_list" ]; then rm "$dl_list"; fi; touch "$dl_list"
	if [ ! -d "$data_dir" ]; then mkdir -p "$data_dir"; fi
	
	#################################################
	## Check that the obsID list exists for a propID
	#################################################
	if [ ! -e "$obsID_list" ]; then
		echo -e "\tERROR: obsID list does not exist. Continuing to next propID."
		continue
	fi
	
	########################################################
	## Check that there are no duplicate obsIDs in the list
	########################################################
	
	python -c "from tools import no_duplicates; no_duplicates('$obsID_list')"
	
	###################################################################
	## Looping through each obs ID
	## Make a list of the web archive address of each directory I want
	###################################################################
	
	for obsID in $( cat "$obsID_list" ); do
		web_dir="${web_archive}/$obsID/"
		
		#############################################
		## Append to list to download
		## Only get the obsIDs I don't already have
		#############################################
		
		if [ ! -d "$data_dir/$obsID" ]; then
			echo "$web_dir" >> "$dl_list"
		fi
	done
	
	###################################################################
	## If there's nothing in the download list, tell the user and exit
	###################################################################
	
	if (( $( wc -l < $dl_list ) == 0 )); then
		echo -e "\tNothing new to download. Continuing to next propID."
		continue
	fi
	
	#######################################################################
	## Download remote directories with wget (allows for recursive DLing!)
	#######################################################################
	
	echo "List of files to be downloaded: $dl_list"
	echo "Download log: $dl_log"
	
	wget -r -P $data_dir -a $dl_log -nv -nH --cut-dirs=5 -i "$dl_list"
	
	##	-r: recursive, i.e. get that and all sub-directories
	##	-P: let the directory specified be the parent directory for saving
	##  -nv: non-verbose (i.e. don't print much)
	##	-nH: cut the web address out of the directory saving name
	##  -a: append output to specified log file
	##	-cut-dirs=5: just keep the obsID and propID in the directory name
	##	-i: download the following list of directories
	
# 	break
done

################################################################################
## All done!
echo "Finished data_dl.sh"

################################################################################
