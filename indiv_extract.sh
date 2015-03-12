#!/bin/bash

################################################################################
## 
## Extracts light curves and spectra for individual obsIDs, for Standard-2, 
## Standard-1, and event-mode data.
##
## Notes: HEASOFT 6.14 (or higher), bash 3.*, and Python 2.7.* (with supporting
##        libraries) must be installed in order to run this script. 
##
## Written by Abigail Stevens, A.L.Stevens at uva.nl, 2015
## 
################################################################################

## Make sure the input arguments are ok
if (( $# != 6 )); then
    echo -e "\t\tUsage: ./indiv_extract.sh <list dir> <out dir> <progress log> \
<gti file> <std2 pcu2 col list> <bitmask file>\n"
    exit
fi

indivextract_args=( "$@" )

list_dir="${indivextract_args[0]}"
out_dir="${indivextract_args[1]}"
progress_log="${indivextract_args[2]}"
gti_file="${indivextract_args[3]}"
std2pcu2_cols="${indivextract_args[4]}"
bitfile="${indivextract_args[5]}"

################################################################################

## If heainit isn't running, start it
if (( $(echo $DYLD_LIBRARY_PATH | grep heasoft | wc -l) < 1 )); then
	. $HEADAS/headas-init.sh
fi

sa_cols="$out_dir/std2_cols.pcu"
cat "$std2pcu2_cols" > "$sa_cols"
ls $out_dir/std2*.pca > "$out_dir/std2.lst"
ls $out_dir/vle*.pca > "$out_dir/vle.lst"
ls $out_dir/evt*.pca > "$out_dir/evt.lst"	

## If there are multiple event files per obsID with different mode prefixes,
## this program will overwrite it the next go-through, so it's all fine!
## I explicitly don't use 'sa_list' or 'se_list' because those are for 
## reduce_alltogether.sh.

################################################################################
################################################################################

##############################
## Extracting Standard-2 data
##############################

if (( $(wc -l < "$out_dir/std2.lst") == 0 )); then
	echo -e "\tERROR: No Standard-2 data files. Cannot run saextrct."
	echo -e "\tERROR: No Standard-2 data files. Cannot run saextrct." >> $progress_log
else
	echo "Extracting Std2 data" >> $progress_log

	saextrct lcbinarray=10000000 \
		maxmiss=200 \
		infile=@"$out_dir/std2.lst" \
		gtiorfile=- \
		gtiandfile="$gti_file" \
		outroot="$out_dir/std2" \
		columns=@"$sa_cols" \
		accumulate=ONE \
		timecol=TIME \
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

	if [ ! -e "$out_dir/std2.pha" ]; then
		echo -e "\tERROR: Std2 spectrum not made!"
		echo -e "\tERROR: Std2 spectrum not made!" >> $progress_log
	# 	continue
	fi 
	if [ ! -e "$out_dir/std2.lc" ]; then
		echo -e "\tERROR: Std2 light curve not made!"
		echo -e "\tERROR: Std2 light curve not made!" >> $progress_log
	# 	continue
	fi
	
	echo "SAEXTRCT finished"
fi

## Get the VLE rates from std1b files
# if (( $(wc -l < "$out_dir/vle.lst") == 0 )); then
# 	echo -e "\tERROR: No VLE data files. Cannot run saextrct."
# 	echo -e "\tERROR: No VLE data files. Cannot run saextrct." >> $progress_log
# else
# 	saextrct lcbinarray=10000000 \
# 		maxmiss=200 \
# 		infile=@"$out_dir/vle.lst" \
# 		gtiorfile=- \
# 		gtiandfile="$gti_file"  \
# 		outroot="$out_dir/vle" \
# 		columns=VLECnt \
# 		accumulate=ONE \
# 		timecol=TIME \
# 		binsz=0.125 \
# 		mfracexp=INDEF \
# 		printmode=LIGHTCURVE \
# 		lcmode=RATE \
# 		spmode=SUM \
# 		mlcinten=INDEF \
# 		mspinten=INDEF \
# 		writesum=- \
# 		writemean=- \
# 		timemin=INDEF \
# 		timemax=INDEF \
# 		timeint=INDEF \
# 		chmin=INDEF \
# 		chmax=INDEF \
# 		chint=INDEF \
# 		chbin=INDEF \
# 		dryrun=no \
# 		clobber=yes
# 	
# 	if [ ! -e "$out_dir/vle.lc" ]; then
# 		echo -e "\tERROR: VLE light curve not made!"
# 		echo -e "\tERROR: VLE light curve not made!" >> $progress_log
# 	# 	continue
# 	fi
# 	
# 	echo "SAEXTRCT finished"
# fi

################################################################################

##############################
## Extracting event-mode data
##############################
			
if (( $(wc -l < "$out_dir/evt.lst") == 0 )); then
	echo -e "\tERROR: No event-mode data files. Cannot run seextrct."
	echo -e "\tERROR: No event-mode data files. Cannot run seextrct." >> $progress_log
else
	echo "Extracting event data" >> $progress_log
	## May need to set lcbinarray to 800000 or INDEF if getting a segmentation
	## fault.
	## Don't put *any* spaces after the '\' end-of-line slashes. TGIF.
	
	seextrct lcbinarray=1600000 \
		maxmiss=INDEF \
		infile=@"$out_dir/evt.lst" \
		gtiorfile=- \
		gtiandfile="$gti_file" \
		outroot="$out_dir/event" \
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

	# if [ ! -e "$out_dir/event.lc" ] ; then
	# 	echo -e "\tERROR: Event-mode light curve not made!"
	# 	echo -e "\tERROR: Event-mode light curve not made!" >> $progress_log
	# # 	continue
	# fi
	if [ ! -e "$out_dir/event.pha" ] ; then
		echo -e "\tERROR: Event-mode spectrum not made!"
		echo -e "\tERROR: Event-mode spectrum not made!" >> $progress_log
	# 	continue
	fi 

	echo "SEEXTRCT finished"
fi

################################################################################
