#!/bin/bash

################################################################################
##
## This bash version was written by Abigail Stevens, 2015-2016
## 
## Based on xtescan2 by Simon Vaughan 2007, modified by Phil Uttley to
## determine configs for a list of obs-IDs rather than a single 
## proposal and target.
##
## Bash script to extract PCA/EA configurations from entire proposal-object set
## of XTE data (using FTOOLS)
##
## Calling sequence:
##    ./xtescan.sh <filename prefix> <obsid list> 
##
## Example:
##    > ./xtescan.sh cygx1 obsid.lst 
##
## Output are the following files:
##     <fileprefix>_allinfo.lst     - details of every file
##     <fileprefix>_config.lst      - list of unique data modes
##     <fileprefix>_<datamode>.lst  - one per unique data mode
##
## History:
##		13/04/2007 -- v1.0 -- first working version
##      18/04/2007 -- v1.1 -- added .xdf output files
##      17/05/2007 -- philv1.2 -- modified to use input obsid list
##	    02/02/2015 -- abbiev1.3 -- now in bash, flipped order of inputs
##      11/02/2015 -- abbiev1.5 -- uses xargs to trim leading whitespace from 
##								   number variables
##		02/09/2015 -- abbiev1.6 -- only takes list of obsIDs, no propIDs needed.
##
################################################################################

## Make sure the input arguments are ok
if (( $# != 2 )); then
    echo -e "\t\tUsage: ./xtescan.sh <filename prefix> <obsID list>\n"
    exit
fi

prefix=$1   ## Prefix for files (either propID or object nickname)
obslist=$2  ## List of obsIDs for the files we want to use.

home_dir=$(ls -d ~)  ## The home directory of this machine
list_dir="$home_dir/Dropbox/Lists"
reduced_dir="$home_dir/Reduced_data/${prefix}"

if [ ! -d "$reduced_dir" ]; then mkdir -p "$reduced_dir"; fi

allinfo_list="$reduced_dir/${prefix}_allinfo.lst"
config_list="$reduced_dir/${prefix}_config.lst"

## Clear files for recording output
if [ -e $allinfo_list ]; then rm -f $allinfo_list; fi; touch $allinfo_list
if [ -e $config_list ]; then rm -f $config_list; fi; touch $config_list

################################################################################
	
########################
## Loop over all obsIDs
########################

for obsid in $( cat "$obslist" ) ; do

	IFS='-' read -a array <<< "$obsid"
	propID=$( echo P"${array[0]}" )
	data_dir="$home_dir/Data/RXTE/$propID"

# 		echo "$data_dir"

	if [ ! -d "$data_dir/$obsid" ]; then
		echo -e "\tERROR: Data directory for $obsid does not exist."
		continue
	fi

	## List all the PCA science files
	ls "$data_dir/$obsid"/pca/FS* > pcafiles.lst
	n=$( cat pcafiles.lst | wc -l )
	if (( n == 0 )); then
		echo -e "\tERROR: No PCA science files for $obsid."
		continue
	else
		echo "Searching $obsid, found $n files." | xargs
	fi

	## Loop over each PCA data file within the ObsID
	i=0
	for pcafile in $( more pcafiles.lst ); do
		(( i++ ))
# 		if [ ${pcafile##*.} == gz ]; then  ## If it's gzipped
# 				gunzip -f "$pcafile"
# 				pcafile="${pcafile%.*}"
# 		fi

		## Extract the PCA/EA data conguration/mode from PCA data file
		datamode=$( python -c "from tools import get_key_val; print get_key_val('$pcafile', 1, 'DATAMODE')" )
		IFS='_' read -a datamodearray <<< "$datamode"

		## Find time resolution from PCA data file
		if [ ${datamodearray[0]} == "B" ] || [ ${datamodearray[0]} == "CB" ] || [ ${datamodearray[0]} == "SB" ]; then
			deltaT=$( python -c "from tools import get_key_val; print get_key_val('$pcafile', 1, '1CDLT2')" )
			echo "$deltaT" > timestep.txt
		else
			deltaT=$( python -c "from tools import get_key_val; print get_key_val('$pcafile', 1, 'TIMEDEL')" )
			echo "$deltaT"
			echo "$deltaT" > timestep.txt
		fi

		## Convert from scientific (1.0E-1) notation to floating if needed (for 'bc')
		if grep -q "e" timestep.txt; then
			echo "Scientific notation"
			float=$(echo $deltaT | cut -d 'e' -f1 )
			expo=$( echo $deltaT | cut -d 'e' -f2 )
			echo "FLOAT=$float"
			echo "EXPO=$expo"
			if (( float != expo )); then
				deltaT=$( echo "scale=14; ($float)*10^($expo)" | bc -l )
			fi
		fi

		## Convert dT from floating point seconds to 2^x seconds
		dt=$( echo "scale=14 ; l($deltaT)/l(2.0)" | bc -l )
		dt2=$( echo "scale=0 ; ($dt)/1" | bc -l )

		## Extract the obs time from PCA data file
		obstime=$( python -c "from tools import get_key_val; print get_key_val('$pcafile', 1, 'TSTART')" )

		## Extract the obs date and (hh:mm:ss) time from PCA data file
		obsdate=$( python -c "from tools import get_key_val; print get_key_val('$pcafile', 1, 'DATE-OBS')" )

		## Tell the user what we have found so far
		echo -e "\t$i /$n -- $datamode $deltaT 2^$dt2" | xargs

		## For this file add the filename, config, date and time to the output file
		echo "$pcafile $datamode $obsdate 2^$dt2" >> $allinfo_list

		## Check whether the datamode for the current file is listed in the list of datamodes.
		## If not then add it to the list of (unique) datamodes
		grep $datamode $config_list > config.txt
		foundit=$( cat config.txt | wc -l )
		if (( foundit == 0 )); then
			echo $datamode >> $config_list
		fi

	## End of loop over PCA data files within the ObsID
	done

## End of loop over each ObsID
done

echo ""

################################################################################
## For each unique datamode used, make a list of filenames

echo "Number of files per unique PCA data mode:"
echo ""
for datamode in $( more $config_list ); do
	list_file="$reduced_dir/${prefix}_${datamode}.lst"
	if [ -e $list_file ]; then rm -f $list_file; fi; touch $list_file
	grep $datamode $allinfo_list >> $list_file
	count=$( cat $list_file | wc -l )
	echo -e "\t$count $datamode" | xargs
	
	## Put the filenames only in an .xdf file, with full path

    cat $list_file | cut -d ' ' -f1 > temp.xdf
    xdf_file="$list_dir/${prefix}_${datamode}.xdf"
    if [ -e $xdf_file ]; then rm -f $xdf_file; fi; touch $xdf_file
    for files in $(more temp.xdf); do
		echo $files >> $xdf_file
    done
done

## Tell the user where the output files are
if [ -e ${prefix}_allinfo.lst ]; then echo "All data in file ${prefix}_allinfo.lst"; fi
echo "Information on each data mode in files ${prefix}_<datamode>.lst"
echo "                                       ${prefix}_<datamode>.xdf"
echo ""

################################################################################
## All done
if [ -e timestep.txt ]; then rm -f timestep.txt; fi
if [ -e timestart.txt ]; then rm -f timestart.txt; fi
if [ -e datamode.txt ]; then rm -f datamode.txt; fi
if [ -e config.txt ]; then rm -f config.txt; fi

echo "Finished xtescan.sh."

################################################################################
