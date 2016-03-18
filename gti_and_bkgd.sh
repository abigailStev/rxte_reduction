#! /bin/bash

################################################################################
## 
## Make GTI file, background file, and extract background spectrum per obsID.
##
## Notes: HEASOFT 6.14 (or higher), bash 3.*, and Python 2.7.* (with supporting
##        libraries) must be installed in order to run this script. 
##
## Inspired by/Based on G. Lamer and P. Uttley's tcsh script 'getgtibackxrb'
## Written by Abigail Stevens <A.L.Stevens at uva.nl>, 2014-2016
## 
################################################################################

## Make sure the input arguments are ok
if (( $# != 11 )); then
    echo -e "\t\tUsage: ./gti_and_bkgd.sh \n"
    exit
fi

gtibkgd_args=( "$@" )
# echo "${gtibkgd_args[@]}"

list_dir="${gtibkgd_args[0]}"
script_dir="${gtibkgd_args[1]}"
out_dir="${gtibkgd_args[2]}"
progress_log="${gtibkgd_args[3]}"
gti_file="${gtibkgd_args[4]}"
filter_file="${gtibkgd_args[5]}"
filtex="${gtibkgd_args[6]}"
bkgd_model="${gtibkgd_args[7]}"
saa_history="${gtibkgd_args[8]}"
std2pcu2_cols="${gtibkgd_args[9]}"
evt_bkgd_list="${gtibkgd_args[10]}"

################################################################################

## If heainit isn't running, start it
if (( $(echo $DYLD_LIBRARY_PATH | grep heasoft | wc -l) < 1 )); then
	. $HEADAS/headas-init.sh
fi

################################################################################
################################################################################

if [ -e $gti_file ]; then rm $gti_file; fi

#######################################
## Making the GTI from the filter file
#######################################

echo "Now making GTI and background for std2 and event mode."

bin_loc=$(python -c "from tools import get_key_val; print get_key_val('$filter_file', 0, 'TIMEPIXR')")
echo "TIMEPIXR = $bin_loc"

if (( bin_loc == 0 )); then
	maketime infile=$filter_file outfile=$gti_file expr=$filtex name=NAME \
		value=VALUE time=Time compact=no clobber=yes prefr=0.0 postfr=1.0
elif (( bin_loc == 1 )); then
	maketime infile=$filter_file outfile=$gti_file expr=$filtex name=NAME \
		value=VALUE time=Time compact=no clobber=yes prefr=1.0 postfr=0.0
else
	echo "Warning: TIMEPIXR is neither 0 nor 1. Setting prefr=postfr=0.5."
	echo "Warning: TIMEPIXR is neither 0 nor 1. Setting prefr=postfr=0.5." >> $progress_log
	maketime infile=$filter_file outfile=$gti_file expr=$filtex name=NAME \
		value=VALUE time=Time compact=no clobber=yes prefr=0.5 postfr=0.5
fi
if [ ! -e "$gti_file" ]; then
	echo -e "\tERROR: Maketime failed. GTI file was not created."
	echo -e "\tERROR: Maketime failed. GTI file was not created." >> $progress_log
	continue
fi

################################################################################
## Looping through the Standard-2 files to make a background and extract a 
## background spectrum for each of them. Two different backgrounds are made 
## because Standard-2 and event-mode backgrounds require different flags.
################################################################################

cp "$std2pcu2_cols" ./tmp_std2_pcu2_cols.lst

m=1
for std2_pca_file in $(ls $out_dir/"std2"*.pca); do
	
	############################################################################
	## Standard-2 background
	##
	## These bkgd files don't have gain correction applied. Use them with
	## Standard-2 or Standard-1b data.
	############################################################################
	
	echo "Making Standard-2 background."
	echo "Making Standard-2 background." >> $progress_log
	std2_bkgd=${std2_pca_file%.*}"_std2.bkgd"
 	echo "std2 bkgd file = $std2_bkgd"

 	if [ -e "$std2_pca_file" ] && [ -e "$bkgd_model" ] && \
 		[ -e "$filter_file" ] && [ -e "$saa_history" ]; then

 		pcabackest infile=$std2_pca_file \
 			outfile=$std2_bkgd \
 			modelfile=$bkgd_model \
 			filterfile=$filter_file \
 			layers=yes \
 			saahfile=$saa_history \
 			interval=16 \
 			gaincorr=no \
 			fullspec=no \
 			clobber=yes
 	fi

 	if [ -e "$std2_bkgd" ]; then

 		##########################################################
 		## Extract a spectrum from the Standard-2 background file
 		##########################################################

 		saextrct lcbinarray=10000000 \
 			maxmiss=200 \
 			infile=$std2_bkgd \
 			gtiorfile=- \
 			gtiandfile="$gti_file" \
 			outroot="${std2_bkgd%.*}_bkgd" \
 			columns=@"$std2pcu2_cols" \
 			accumulate=ONE \
 			timecol="Time" \
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

 		if [ ! -e "${std2_bkgd%.*}_bkgd.pha" ]; then
 			echo -e "\tERROR: Standard-2 background spectrum not extracted."
 			echo -e "\tERROR: Standard-2 background spectrum not extracted." >> $progress_log
 		fi
 	else
 		echo -e "\tERROR: Standard-2 background file not made."
 		echo -e "\tERROR: Standard-2 background file not made." >> $progress_log
 	fi
	
	############################################################################
	## Event-mode background
	##
	## These bkgd files are made with the gain correction and full 256 channels,
	## they should be used when data is not good xenon or standard 1 or 2
	## Use this for event-mode data! Need to re-bin in energy channels once I've
	## extracted a spectrum and summed all the spectra of the obsIDs being used.
	############################################################################

	echo "Making event-mode background."
	echo "Making event-mode background." >> $progress_log
	event_bkgd="${std2_pca_file%.*}_evt.bkgd"
	echo "event bkgd file = $event_bkgd"
	
	if [ -e "$out_dir/evt_${m}.pca" ]; then  ## Only process this bkgd if there's 
											 ## an accompanying event-mode file
 		if [ -e "$std2_pca_file" ] && [ -e "$bkgd_model" ] && \
 			[ -e "$filter_file" ] && [ -e "$saa_history" ]; then

 			pcabackest infile=$std2_pca_file \
 				outfile=$event_bkgd \
 				modelfile=$bkgd_model \
 				filterfile=$filter_file \
 				layers=yes \
 				saahfile=$saa_history \
 				interval=16 \
 				gaincorr=yes \
 				gcorrfile=caldb \
 				fullspec=yes \
 				clobber=yes
 		fi
	
		if [ -e "$event_bkgd" ]; then
			echo "$event_bkgd"
		
			##########################################################
			## Extract a spectrum from the event-mode background file
			##########################################################

 			saextrct lcbinarray=10000000 \
 				maxmiss=200 \
 				infile=$event_bkgd \
 				gtiorfile=- \
 				gtiandfile="$gti_file" \
 				outroot="${event_bkgd%.*}_bkgd" \
 				columns=@tmp_std2_pcu2_cols.lst \
 				accumulate=ONE \
 				timecol="Time" \
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

			if [ ! -e "${event_bkgd%.*}_bkgd.pha" ]; then
				echo -e "\tERROR: Event-mode background spectrum not extracted."
				echo -e "\tERROR: Event-mode background spectrum not extracted." >> $progress_log
			else
				echo "${event_bkgd%.*}_bkgd.pha" >> $evt_bkgd_list
			fi
		else
			echo -e "\tERROR: Event-mode background file not made."
			echo -e "\tERROR: Event-mode background file not made." >> $progress_log
	# 		continue
		fi
	fi
# 			
# 		## Good Xenon bkgd files are made with the full 256 channels but no gain
# 	    ## correction
# 		gx_bkgd=${std2_pca_file%.*}"_gx.bkgd"
# 		echo "gx_bkgd = $gx_bkgd"
# 		pcabackest infile=$std2_pca_file \
# 			outfile="$gx_bkgd" \
# 			modelfile=$bkgd_model \
# 			filterfile=$filter_file \
# 			layers=yes \
# 			saahfile=$saa_history \
# 			interval=16 \
# 			gaincorr=no \
# 			fullspec=yes \
# 			clobber=yes  
	(( m++ ))
done

################################################################################
## All done!

## Deleting the temp file(s)
if [ -e tmp_std2_pcu2_cols.lst ]; then rm tmp_std2_pcu2_cols.lst; fi

echo "Finished making GTI and background."
echo "Finished making GTI and background." >> $progress_log

################################################################################
