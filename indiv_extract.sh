#!/bin/bash

## Make sure the input arguments are ok
if (( $# != 3 )); then
    echo -e "\t\tUsage: indiv_extract.sh <output dir> <progress log> <list dir>"
    exit
fi

out_dir=$1
progress_log=$2
list_dir=$3


gti_file="$out_dir/gti_file.gti"

sa_cols="$out_dir/std2_cols.pcu"
echo "sa_cols = $sa_cols"

if [ -e "$out_dir/std2.lst" ]; then rm -f "$out_dir/std2.lst"; fi
ls $out_dir/std2*.pca > "$out_dir/std2.lst"

cat "$list_dir"/std2_pcu2_cols.lst > "$sa_cols"

echo "Extracting std2 data" >> $progress_log
## Getting count rates from std2 files
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
	printmode=SPECTRUM \
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

if [ -e $dump_file ]; then rm -f $dump_file; fi

if [ ! -e "$out_dir/std2.pha" ]; then
	echo -e "\tERROR: $out_dir/std2.pha not made!"
	echo -e "\tERROR: $out_dir/std2.pha not made!" >> $progress_log
fi  ## End 'if $out_dir/std2.pha files not made', i.e. if saextrct failed

ls $out_dir/vle*.pca > "$out_dir/vle.lst"
## Get the VLE rates from std1b files
saextrct lcbinarray=10000000 \
	maxmiss=200 \
	infile=@"$out_dir/vle.lst" \
	gtiorfile=APPLY \
	gtiandfile="$gti_file"  \
	outroot="$out_dir/vle" \
	columns=VLECnt \
	accumulate=ONE \
	timecol=TIME \
	binsz=0.125 \
	mfracexp=INDEF \
	printmode=LIGHTCURVE \
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

if [ -e $dump_file ] ; then rm -f $dump_file; fi

echo "SAEXTRCT finished"
echo "SAEXTRCT finished" >> $progress_log


#####################################################
## Start of extracting time-resolved event-mode data
#####################################################

if [ -e "$out_dir/evt.lst" ]; then rm -f "$out_dir/evt.lst"; fi
ls $out_dir/evt*.pca > "$out_dir/evt.lst"
if [ -e "$out_dir/evt_1.pca" ]; then
	time_res=$(python "$script_dir"/get_keyword.py "$out_dir/evt_1.pca" 1 TIMEDEL 1)
	echo "Time resolution of raw data = $time_res s" >> $progress_log
fi					
echo "$out_dir/evt.lst" >> $progress_log

echo "Extracting event data" >> $progress_log
## Extract time-resolved event-mode data
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
	printmode=BOTH \
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

if [ ! -e "$out_dir/event.lc" ] ; then
	echo -e "\tERROR: $out_dir/event.lc not made!"
	echo -e "\tERROR: $out_dir/event.lc not made!" >> $progress_log
fi  ## End 'if $out_dir/event.lc files not made', i.e. if saextrct failed
if [ ! -e "$out_dir/event.pha" ] ; then
	echo -e "\tERROR: $out_dir/event.pha not made!"
	echo -e "\tERROR: $out_dir/event.pha not made!" >> $progress_log
fi  ## End 'if $out_dir/event.lc files not made', i.e. if 

echo "SEEXTRCT finished"
echo "SEEXTRCT finished" >> $progress_log