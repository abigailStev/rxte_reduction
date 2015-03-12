#!/bin/bash

################################################################################
## 
## Extracts light curves and spectra for individual obsIDs, for Standard-2, 
## Standard-1, and event-mode data.
##
## Example call: ./indiv_extract.sh /out/put/dir progress.log
##
## Change the directory names and specifiers before the double '#' row to best
## suit your setup.
##
## Notes: HEASOFT 6.14 (or higher), bash 3.*, and Python 2.7.* (with supporting
##        libraries) must be installed in order to run this script. 
##
## Written by Abigail Stevens, A.L.Stevens at uva.nl, 2015
## 
################################################################################

## Make sure the input arguments are ok
if (( $# != 2 )); then
    echo -e "\t\tUsage: ./indiv_extract.sh <output dir> <progress log>\n"
    exit
fi

out_dir=$1
progress_log=$2

################################################################################

## If heainit isn't running, start it
if (( $(echo $DYLD_LIBRARY_PATH | grep heasoft | wc -l) < 1 )); then
	. $HEADAS/headas-init.sh
fi

home_dir=$(ls -d ~) 
list_dir="$home_dir/Dropbox/Lists"
gti_file="$out_dir/gti_file.gti"

sa_cols="$out_dir/std2_cols.pcu"
cat "$list_dir"/std2_pcu2_cols.lst > "$sa_cols"

################################################################################
################################################################################

##############################
## Extracting Standard-2 data
##############################

if [ -e "$out_dir/std2.lst" ]; then rm -f "$out_dir/std2.lst"; fi
ls $out_dir/std2*.pca > "$out_dir/std2.lst"
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

# ls $out_dir/vle*.pca > "$out_dir/vle.lst"
# ## Get the VLE rates from std1b files
# 
# saextrct lcbinarray=10000000 \
# 	maxmiss=200 \
# 	infile=@"$out_dir/vle.lst" \
# 	gtiorfile=APPLY \
# 	gtiandfile="$gti_file"  \
# 	outroot="$out_dir/vle" \
# 	columns=VLECnt \
# 	accumulate=ONE \
# 	timecol=TIME \
# 	binsz=0.125 \
# 	mfracexp=INDEF \
# 	printmode=LIGHTCURVE \
# 	lcmode=RATE \
# 	spmode=SUM \
# 	mlcinten=INDEF \
# 	mspinten=INDEF \
# 	writesum=- \
# 	writemean=- \
# 	timemin=INDEF \
# 	timemax=INDEF \
# 	timeint=INDEF \
# 	chmin=INDEF \
# 	chmax=INDEF \
# 	chint=INDEF \
# 	chbin=INDEF \
# 	dryrun=no \
# 	clobber=yes
# 
echo "SAEXTRCT finished"

################################################################################

##############################
## Extracting event-mode data
##############################

if [ -e "$out_dir/evt.lst" ]; then rm -f "$out_dir/evt.lst"; fi
ls $out_dir/evt*.pca > "$out_dir/evt.lst"				
echo "Extracting event data" >> $progress_log

## Don't put *any* spaces after the \ slashes. TGIF.
## Using bitfile_evt_PCU2 for only PCU2 photons

seextrct infile=@"$out_dir/evt.lst" \
	maxmiss=INDEF \
	gtiorfile=- \
	gtiandfile="$gti_file" \
	outroot="$out_dir/event" \
	bitfile="$list_dir"/bitfile_evt_PCU2 \
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

################################################################################
