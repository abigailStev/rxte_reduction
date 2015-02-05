#!/bin/bash

###############################################################################
##
## Downloads raw data directories from the RXTE remote archives.
## Requires a list of proposal IDs with the archive prefix, and for each
## proposal ID a corresponding list of obsIDs to download.
##
## Usage: ./data_dl.sh <proposal_ID_list>
##
## Written by Abigail Stevens, A.L.Stevens@uva.nl, 2013-2015
###############################################################################

## Make sure the input arguments are ok
if (( $# != 1 )); then
    echo -e "\t\tUsage: ./data_dl.sh <proposal ID list>"
    exit
fi

propID_list=$1

home_dir=$(ls -d ~)
list_dir="$home_dir/Dropbox/Lists"
data_dir_prefix="$home_dir/Data/RXTE"
web_prefix="ftp://legacy.gsfc.nasa.gov/xte/data/archive"
dl_log="$home_dir/Dropbox/Research/rxte_reduce/download.log"

if [ ! -e "$propID_list" ]; then
	echo -e "\tERROR: proposal ID list does not exist. Exiting."
	exit
fi

if [ -e "$dl_log" ]; then rm "$dl_log"; fi

###############################################################################
for line in $( cat "$propID_list" ); do
	
	IFS=',' read -a array <<< "$line"
	archive_prefix="${array[0]}"	
	propID="${array[1]}"
	
	echo "Proposal ID: $propID"
	
	data_dir="${data_dir_prefix}/$propID"
	obsID_list="$list_dir/${propID}_dl_obsIDs.txt"
	dl_list="$list_dir/${propID}_downloads.txt"
	web_archive="${web_prefix}/${archive_prefix}/$propID"
	
	if [ -e "$dl_list" ]; then rm "$dl_list"; fi; touch "$dl_list"
	if [ ! -d "$data_dir" ]; then mkdir -p "$data_dir"; fi

	if [ ! -e "$obsID_list" ]; then
		echo -e "\tERROR: obsID list does not exist. Continuing to next propID."
		continue
	fi
	
# 	echo $( wc -l < $obsID_list )
	python -c "from tools import no_duplicates; no_duplicates('$obsID_list')"
# 	echo $( wc -l < $obsID_list )
	
	## Make a list of the web archive address of each directory of obsIDs I want
	for obsID in $( cat "$obsID_list" ); do
		web_dir="$web_archive/$obsID/"

		## Only get the obsIDs I don't already have
# 		if [ ! -d "$data_dir/$obsID" ]; then
			echo "$web_dir" >> "$dl_list"
# 		fi
	done
	
	## If there's nothing in the download list, tell the user and exit.
	if (( $(wc -l < $dl_list) == 0 )); then
		echo -e "\tNothing new to download. Continuing to next propID."
		continue
	fi
	
	###############################################
	## Download those remote directories with wget
	################################################
	
	wget -r -P $data_dir -a $dl_log -nv -nH --cut-dirs=5 -i "$dl_list"
	
	##	-r: recursive, i.e. get that and all sub-directories
	##	-P: let the directory specified be the parent directory for saving
	##  -q: quiet (i.e. don't print much at all to the screen)
	##	-nH: cut the web address out of the directory saving name
	##  -a: append output to specified log file
	##	-cut-dirs=5: literally all i want to save the name as is 'obsID' in the parent dir
	##	-i: download the following list of directories
	break
done

###############################################################################
## Can run xtescan on the data after it's downloaded

time "$home_dir/Dropbox/Research/rxte_reduce"/xtescan.sh j1808-1HzQPO "$propID_list"

###############################################################################
## All done!
echo "Finished data_dl.sh"

###############################################################################