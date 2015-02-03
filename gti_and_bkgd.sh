#! /bin/bash
###############################################################################
## 
## Make GTI file and background file for rxte_reduce_data.sh
## Runs HEASOFT scripts maketime and pcabackest, and Abbie's tools.py
## Inspired by G. Lamer (gl@astro.soton.ac.uk)'s script 'getgtibackxrb'
##     or maybe Phil wrote the c-shell version, it's unclear.
## 
## 
###############################################################################


## Make sure the input arguments are ok
if (( $# != 4 )); then
    echo -e "\t\tUsage: ./gti_and_bkgd.sh <output dir> <filter expression> <progress log> <evt bkgd list>"
    exit
fi

out_dir=$1
filtex=$2
progress_log=$3
evt_bkgd_list=$4

## If heainit isn't running, start it
if (( $(echo $DYLD_LIBRARY_PATH | grep heasoft | wc -l) < 1 )); then
	. $HEADAS/headas-init.sh
fi

filter_file="$out_dir/filter.xfl"
gti_file="$out_dir/gti_file.gti"
home_dir=$(ls -d ~)  # the -d flag is extremely important here
list_dir="$home_dir/Dropbox/Lists"
script_dir="$home_dir/Dropbox/Research/rxte_reduce"

echo "Now making GTI and background for std2 and event mode."

if [ -e $gti_file ]; then rm $gti_file; fi

bkgd_model="$list_dir/pca_bkgd_cmbrightvle_eMv20051128.mdl"  ## good for > 40 counts/sec/pcu
# bkgd_model="$list_dir/pca_bkgd_cmfaintl7_eMv20051128.mdl"  ## good for < 40 counts/sec/pcu
saa_history="$list_dir/pca_saa_history"

bin_loc=$(python -c "from tools import get_key_val; print get_key_val('$filter_file', 0, 'TIMEPIXR')")
echo "TIMEPIXR = $bin_loc"

if (( bin_loc == 0 )); then
# 	echo "In here 1"
	maketime infile=$filter_file outfile=$gti_file expr=$filtex name=NAME \
		value=VALUE time=Time compact=no clobber=yes prefr=0.0 postfr=1.0
elif (( bin_loc == 1 )); then
# 	echo "In here 2"
	maketime infile=$filter_file outfile=$gti_file expr=$filtex name=NAME \
		value=VALUE time=Time compact=no clobber=yes prefr=1.0 postfr=0.0
else
# 	echo "In here 3"
	maketime infile=$filter_file outfile=$gti_file expr=$filtex name=NAME \
		value=VALUE time=Time compact=no clobber=yes prefr=0.5 postfr=0.5
fi
if [ ! -e "$gti_file" ]; then
	echo -e "\tERROR: Maketime failed. $gti_file was not created."
	echo -e "\tERROR: Maketime failed. $gti_file was not created." >> $progress_log
fi

for std2_pca_file in $(ls $out_dir/"std2"*.pca); do
# 	
# 		## Use these with standard 1 or 2 data -- don't have gain correction applied.
# 		std2_bkgd=${std2_pca_file%.*}"_std2.bkgd"
# 		echo "std2 bkgd file = $std2_bkgd"
# 		pcabackest infile=$std2_pca_file \
# 			outfile=$std2_bkgd \
# 			modelfile=$bkgd_model \
# 			filterfile=$filter_file \
# 			layers=yes \
# 			saahfile=$saa_history \
# 			interval=16 \
# 			gaincorr=no \
# 			fullspec=no \
# 			clobber=yes  	
# 		
# 		if [ -e "$std2_bkgd" ]; then
# 			cols="$out_dir/std2_pcu2_cols.pcu"
# 			cat "$list_dir"/std2_pcu2_cols.lst > "$cols"
# 			
# 			## Extract a spectrum from the Standard Mode 2 background file
# 			saextrct lcbinarray=10000000 \
# 				maxmiss=200 \
# 				infile=$std2_bkgd \
# 				gtiorfile=- \
# 				gtiandfile="$gti_file" \
# 				outroot="${std2_bkgd%.*}_bkgd" \
# 				columns=@"$cols" \
# 				accumulate=ONE \
# 				timecol=TIME \
# 				binsz=16 \
# 				mfracexp=INDEF \
# 				printmode=SPECTRUM \
# 				lcmode=RATE \
# 				spmode=SUM \
# 				mlcinten=INDEF \
# 				mspinten=INDEF \
# 				writesum=- \
# 				writemean=- \
# 				timemin=INDEF \
# 				timemax=INDEF \
# 				timeint=INDEF \
# 				chmin=INDEF \
# 				chmax=INDEF \
# 				chint=INDEF \
# 				chbin=INDEF \
# 				dryrun=no \
# 				clobber=yes
# 				
# 			if [ ! -e "${std2_bkgd%.*}_bkgd.pha" ]; then
# 				echo -e "\tERROR: Standard-2 background spectrum not extracted."
# 				echo -e "\tERROR: Standard-2 background spectrum not extracted." >> $progress_log
# 			fi
# 		else
# 			echo -e "\tERROR: Standard-2 background file not made."
# 			echo -e "\tERROR: Standard-2 background file not made." >> $progress_log
# 		fi
# 		
# 		
	## These bkgd files are made with the gain correction and full 256 channels,
	## they should be used when data is not good xenon or standard 1 or 2
	## Use this for event-mode data! need to re-bin once i've extracted a spectrum
	echo "Making event-mode background."
	echo "Making event-mode background." >> $progress_log
	event_bkgd="${std2_pca_file%.*}_evt.bkgd"
	echo "event bkgd file = $event_bkgd"
	
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
	
	if [ -e "$event_bkgd" ]; then
		echo "$event_bkgd"
		cols="$out_dir/std2_pcu2_cols.pcu"
		cp "$list_dir"/std2_pcu2_cols.lst "$cols"
		echo "$cols"
# 		open "$cols"
		## Extract a spectrum from the event mode background file
		saextrct lcbinarray=10000000 \
			maxmiss=200 \
			infile=$event_bkgd \
			gtiorfile=- \
			gtiandfile="$gti_file" \
			outroot="${event_bkgd%.*}_bkgd" \
			columns=@"$cols" \
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

		if [ ! -e "${event_bkgd%.*}_bkgd.pha" ]; then
			echo -e "\tERROR: Event-mode background spectrum not extracted."
			echo -e "\tERROR: Event-mode background spectrum not extracted." >> $progress_log
		else
			echo "${event_bkgd%.*}_bkgd.pha" >> $evt_bkgd_list
		fi
	else
		echo -e "\tERROR: Event-mode background file not made."
		echo -e "\tERROR: Event-mode background file not made." >> $progress_log
# 		exit
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
# 
done

echo "Finished making GTI and std2 background."
echo "Finished making GTI and std2 background." >> $progress_log
