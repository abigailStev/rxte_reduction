#!/bin/bash

################################################################################
##
## Downloads raw data directories from the RXTE remote archives.
## Requires a list of proposal IDs with the archive prefix, and for each
## proposal ID a corresponding list of obsIDs to download.
##
## Usage: ./download_obsIDs.sh <proposal_ID_list>
##
## Written by Abigail Stevens, A.L.Stevens@uva.nl, 2013-2017
## 
################################################################################

## Make sure the input arguments are ok
if (( $# != 1 )); then
    echo -e "\t\tUsage: ./download_obsIDs.sh <proposal ID list>"
    exit
fi

obsID_list=$1


home_dir=$(ls -d ~)
list_dir="$home_dir/Dropbox/Lists"
data_dir="$home_dir/Data/RXTE"  ## Saves as {data_dir_prefix}/propID/obsID
dl_log="$home_dir/Dropbox/Research/rxte_reduce/download.log"
dl_list="$list_dir/new_downloads.txt"
web_prefix="ftp://legacy.gsfc.nasa.gov/xte/data/archive"  ## The web archive prefix

################################################################################
################################################################################

if [ ! -e "$obsID_list" ]; then
	echo -e "\tERROR: observation ID list does not exist."
	exit
fi

if [ -e "$dl_log" ]; then rm "$dl_log"; fi
if [ -e "$dl_list" ]; then rm "$dl_list"; fi; touch "$dl_list"

########################################################
## Check that there are no duplicate obsIDs in the list
########################################################
	
python -c "from tools import no_duplicates; no_duplicates('$obsID_list')"

count=1
num_obsIDs=$( wc -l < "$obsID_list" )
if (( $num_obsIDs == 0 )); then
	echo -e "\tERROR: Observation ID list exists but is empty: $obsID_list"
	exit
fi

##############################
## Looping through each obsID
##############################

for obsID in $( cat "$obsID_list" ); do

	echo "ObsID $count /$num_obsIDs: ${obsID}" | xargs
	
	###################
	## Get proposal ID
	###################
	
	IFS='-' read -a array <<< "$obsID"
	propID=$( echo P"${array[0]}" )
	
	######################
	## Get archive prefix
	######################
	
	temp1=$( echo "${array[0]}" | cut -c 1 )
	if (( $temp1 < 9 )); then
		archive_prefix="AO${temp1}"
	else
		(( temp2=$( echo "${array[0]}" | cut -c 2 )+9 ))
		archive_prefix="AO${temp2}"
	fi

	############################################
	## Append to list to download
	## Only get the obsIDs I don't already have
	############################################
	
	web_dir="${web_prefix}/${archive_prefix}/$propID/$obsID/"

	if [ ! -d "$data_dir/$propID/$obsID" ]; then
		echo "$web_dir" >> "$dl_list"
	fi
	
	(( count++ ))
	
done

###################################################################
## If there's nothing in the download list, tell the user and exit
###################################################################

if (( $( wc -l < "$dl_list" ) == 0 )); then
	echo -e "\tNothing new to download!"
	exit
fi

#######################################################################
## Download remote directories with wget (allows for recursive DLing!)
#######################################################################

echo "List of files to be downloaded: $dl_list"
echo "Download log: $dl_log"

wget -r -P $data_dir -a $dl_log -nv -nH --cut-dirs=4 -i "$dl_list"

##	-r: recursive, i.e. get that and all sub-directories
##	-P: let the directory specified be the parent directory for saving
##  -nv: non-verbose (i.e. don't print much)
##	-nH: cut the web address out of the directory saving name
##  -a: append output to specified log file
##	-cut-dirs=4: just keep the obsID and propID in the directory name
##	-i: download the following list of directories

################################################################################
## All done!
echo "Finished data_dl.sh"

################################################################################
