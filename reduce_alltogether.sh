#!/bin/bash

################################################################################
##
## Final data reduction steps for all observation files together.
##
## Notes: HEASOFT 6.14 (or higher), bash 3.* and Python 2.7.* (with supporting 
##		  libraries) must be installed in order to run this script. Internet 
##        access is required for most setups of CALDB.
## 
## Written by Abigail Stevens, A.L.Stevens at uva.nl, 2015
## 
################################################################################

if (( $# != 13 )); then
	echo -e "\t\tUsage: ./reduce_alltogether.sh <list dir> <script dir> \
<prefix> <progress log> <obsID list> <out dir prefix> <filter list> <filter \
expression> <evt mode bkgd list> <se list> <sa list> <std2 pcu2 col list> \
<bitmask file>"
	exit
fi

alltogether_args=( "$@" )
# echo "${alltogether_args[@]}"

list_dir="${alltogether_args[0]}"
script_dir="${alltogether_args[1]}"
prefix="${alltogether_args[2]}"
progress_log="${alltogether_args[3]}"
obsID_list="${alltogether_args[4]}"
out_dir_prefix="${alltogether_args[5]}"
filter_list="${alltogether_args[6]}"
filtex="${alltogether_args[7]}"
evt_bkgd_list="${alltogether_args[8]}"
se_list="${alltogether_args[9]}"
sa_list="${alltogether_args[10]}"
std2pcu2_cols="${alltogether_args[11]}"
bitfile="${alltogether_args[12]}"

################################################################################

## If heainit isn't running, start it
if (( $(echo $DYLD_LIBRARY_PATH | grep heasoft | wc -l) < 1 )); then
	. $HEADAS/headas-init.sh
fi

out_dir="$out_dir_prefix/${prefix}"
filter_file="$out_dir/all.xfl"
gti_file="$out_dir/all.gti"
all_evt="$out_dir/all_evt.pha"
all_std2="$out_dir/all_std2.pha"
sa_cols="$out_dir/std2_cols.pcu"
evtpha_list="$out_dir/${prefix}_evtpha.lst"  ## Only used if num_evt >= 100

################################################################################
################################################################################

if [ -e "$evtpha_list" ]; then rm "$evtpha_list"; fi; touch "$evtpha_list"
cat "$std2pcu2_cols" > "$sa_cols"

## Removing duplicates from the obsID list -- can happen if there are multiple
## orbits per obsID
python -c "from tools import no_duplicates; no_duplicates('$obsID_list')"

################################################################################
## Now making a filter, gti, event-mode spectrum, Std2 lightcurve and spectrum, 
## adding event-mode background spectra, re-binning the total event-mode 
## background spectrum, and making a response matrix for ALL obsIDs. 
################################################################################

echo "Merging filter files"

## Sort filter files from above chronologically
echo "$filter_list"
python -c "from tools import time_ordered_list; time_ordered_list('$filter_list')" > ./dump.txt
echo ./dump.txt

cp ./dump.txt "$filter_list"

## Merge the filter files into one big one
fmerge infiles=@"$filter_list" \
	outfile="$filter_file" \
	columns=- \
	copyprime=yes \
	lastkey='TSTOP' \
	clobber=yes

if [ ! -e "$filter_file" ] ; then
	echo -e "\tERROR: fmerge did not work, total filter file not made. Exiting."
	echo -e "\tERROR: fmerge did not work, total filter file not made. Exiting." >> $progress_log
	exit
fi

##############################################################
## Make a GTI from the merged filter file for all the obsIDs
##############################################################
echo "Making GTI from merged fiter files"

bin_loc=$(python -c "from tools import get_key_val; print get_key_val('$filter_file', 0, 'TIMEPIXR')")
if (( bin_loc == 0 )); then
	maketime infile=$filter_file outfile=$gti_file expr=$filtex name=NAME \
		value=VALUE time=Time compact=no clobber=yes prefr=0.0 postfr=1.0
elif (( bin_loc == 1 )); then
	maketime infile=$filter_file outfile=$gti_file expr=$filtex name=NAME \
		value=VALUE time=Time compact=no clobber=yes prefr=1.0 postfr=0.0
else
	echo -e"\tWarning: TIMEPIXR is neither 0 nor 1. Setting prefr=postfr=0.5."
	echo -e "\tWarning: TIMEPIXR is neither 0 nor 1. Setting prefr=postfr=0.5." >> $progress_log
	maketime infile=$filter_file outfile=$gti_file expr=$filtex name=NAME \
		value=VALUE time=Time compact=no clobber=yes prefr=0.5 postfr=0.5
fi

if [ ! -e "$gti_file" ] ; then
	echo -e "\tERROR: Total GTI file not made. Exiting."
	echo -e "\tERROR: Total GTI file not made. Exiting." >> $progress_log
	exit
fi

################################################################################
## Make a mean event-mode spectrum -- needed for pcarsp (in event_mode_bkgd.sh)
################################################################################

echo "Extracting MEAN evt spectrum"
echo "Extracting MEAN evt spectrum" >> $progress_log

## If there are no event files, give error and exit.
if (( $( wc -l < $se_list ) == 0 )); then

	echo -e "\tERROR: No event-mode data files for any obsID. Cannot run seextrct. Exiting."
	echo -e "\tERROR: No event-mode data files for any obsID. Cannot run seextrct. Exiting." >> $progress_log
	exit
	
## If there are 100 or more event files, need to add spectra in addpha.py
elif (( $( wc -l < $se_list ) >= 100 )); then

	echo "100 or more event spectra. Adding */event.pha with addpha."
	echo "100 or more event spectra. Adding */event.pha with addpha." >> $progress_log
	
	for obsid in $( cat $obsID_list ); do
		echo "$out_dir/$obsid/event.pha" >> $evtpha_list
	done	
	
	if (( $( wc -l < $evtpha_list ) > 0 )); then
		echo python ./addpha.py "$evtpha_list" "$all_evt" "$gti_file"
		python "$script_dir"/addpha.py "$evtpha_list" "$all_evt" "$gti_file"
	else
		echo -e "\tERROR: addpha.py did not run. No event spectra in list."
		echo -e "\tERROR: addpha.py did not run. No event spectra in list." >> $progress_log
	fi
	
## If there are 0 < n < 100 event files, combine them in seextrct	
else
	seextrct lcbinarray=1600000 \
		maxmiss=INDEF \
		infile=@"$se_list" \
		gtiorfile=- \
		gtiandfile="$gti_file" \
		outroot="${all_evt%.*}" \
		bitfile="$bitfile" \
		timecol="TIME" \
		columns="Event" \
		multiple=yes \
		binsz=1 \
		printmode=SPECTRUM \
		lcmode=RATE \
		spmode=SUM \
		timemin=INDEF \
		timemax=INDEF \
		timeint=INDEF \
		chmin=INDEF \
		chmax=INDEF \
		chint=INDEF \
		chbin=INDEF \
		mode=ql

	if [ ! -e "$all_evt" ] ; then
		echo -e "\tERROR: Total event-mode spectrum not made!"
		echo -e "\tERROR: Total event-mode spectrum not made!" >> $progress_log
	fi  
fi  ## End of 'if there are evt files in $se_list

##################################################
## Make a mean standard-2 spectrum and lightcurve
##################################################

echo "Extracting MEAN std2 pcu 2 data"
echo "Extracting MEAN std2 pcu 2 data" >> $progress_log

if (( $(wc -l < $sa_list) == 0 )); then
	echo -e "\tERROR: No Standard-2 data files for any obsID. Cannot run saextrct."
	echo -e "\tERROR: No Standard-2 data files for any obsID. Cannot run saextrct." >> $progress_log
else
	saextrct lcbinarray=10000000 \
		maxmiss=200 \
		infile=@"$sa_list" \
		gtiorfile=- \
		gtiandfile="$gti_file" \
		outroot="${all_std2%.*}" \
		columns=@"$sa_cols" \
		accumulate=ONE \
		timecol="Time" \
		binsz=16 \
		mfracexp=INDEF \
		printmode=BOTH \
		lcmode=RATE \
		spmode=SUM \
		mlcinten=INDEF \
		mspinten=INDEF \
		writesum=- \
		writemean=- \
		timemin=INDEF \
		timemax=INDEF \
		timeint=INDEF \
		chmin=INDEF \
		chmax=INDEF \
		chint=INDEF \
		chbin=INDEF \
		dryrun=no \
		clobber=yes

	if [ ! -e "${all_std2%.*}.lc" ] ; then
		echo -e "\tERROR: Total Standard-2 light curve not made!"
		echo -e "\tERROR: Total Standard-2 light curve not made!" >> $progress_log
	fi
	if [ ! -e "$all_std2" ] ; then
		echo -e "\tERROR: Total Standard-2 spectrum not made!"
		echo -e "\tERROR: Total Standard-2 spectrum not made!" >> $progress_log
	fi 
fi  ## End 'if there are std2 files in $sa_list'

echo "Done with total extractions."

#######################################################
## Adding the extracted event-mode background spectra.
#######################################################

eventmodebkgd_args=()
eventmodebkgd_args[0]="$script_dir"
eventmodebkgd_args[1]="$list_dir"
eventmodebkgd_args[2]="$out_dir"
eventmodebkgd_args[3]="$evt_bkgd_list"
eventmodebkgd_args[4]="$all_evt"
eventmodebkgd_args[5]="$progress_log"

echo -e "\n" ./event_mode_bkgd.sh "${eventmodebkgd_args[@]} \n" 
"$script_dir"/event_mode_bkgd.sh "${eventmodebkgd_args[@]}" 

######################################################
## Analyzing filter files to see how many PCUs are on
######################################################

analyzefilters_args=()
analyzefilters_args[0]="$script_dir"
analyzefilters_args[1]="$list_dir"
analyzefilters_args[2]="$out_dir"
analyzefilters_args[3]="$prefix"
analyzefilters_args[4]="$filter_list"

echo -e "\n" ./analyze_filters.sh "${analyzefilters_args[@]} \n"
"$script_dir"/analyze_filters.sh "${analyzefilters_args[@]}"

################################################################################
## 					All done!
echo "Finished reduce_alltogether.sh"
echo "Finished reduce_alltogether.sh" >> $progress_log
################################################################################