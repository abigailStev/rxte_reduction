#! /bin/bash

###############################################################################
##
## Extract and reduce RXTE PCA data.
##
## Example call: ./rxte_reduce_data.sh ./newfiles.lst ./obsIDs.lst> run.log
## run.log has the full print outs. The file progress.log is a more concise way
## to keep track of progress.
##
## Inspired by G. Lamer (gl@astro.soton.ac.uk)'s script 'xrbgetprod'
## 
## Notes: heainit needs to already be running!
## 
## 
###############################################################################

## If heainit isn't running, start it
if (( $(echo $DYLD_LIBRARY_PATH | grep heasoft | wc -l) < 1 )); then
	. $HEADAS/headas-init.sh
fi

newfilelist=$1  ## Name of file with list of new data files; used to get the 
				## directories to get the obsIDs, etc
obsID_list=$2  ## File to write a list of obsIDs to, for next steps

home_dir=$(ls -d ~)  ## The home directory of this machine; the -d flag is 
					 ## extremely important here
data_dir="$home_dir/Data/RXTE"  ## Data directory
script_dir="$home_dir/Dropbox/Research/rxte_reduce"  ## Directory containing the
													 ## data reduction scripts
little_scripts="$home_dir/Dropbox/Scripts"  ## Contains python helper scripts
list_dir="$home_dir/Dropbox/Lists"  ## A folder of lists; tells which files we're using
current_dir=$(pwd)  ## The current directory
# out_dir_prefix="$home_dir/Dropbox/Research/Data"  ## Prefix of output directory (for Aeolus)
out_dir_prefix="$home_dir/Reduced_data"  ## Prefix of output directory (for Hera)
target_name="saxj1808"  ## Short colloquial name of the object
dump_file=dum.dat  ## Name of dumping file for intermediary steps
progress_log="$current_dir/progress.log"  ## File with concise description of 
										  ## this script's progress
propID="."  ## Need to declare this here so that it can be used later
std2_lc_dat_files="$list_dir/tmp_std2lc.lst"  ## Temporary list with std2 pcu 2
											  ## files for the light curve
filter_list="$list_dir/tmp_all_filters.lst"  ## This gets changed later on
std2_files="$list_dir/tmp_std2_files.lst"
evt_bkgd_list="$list_dir/tmp_evt_bkgd.lst"


echo "data_dir = $data_dir"
echo "current_dir = $current_dir"
echo "obsID list = $obsID_list"
echo "input newfilelist = $newfilelist"

touch "$std2_lc_dat_files"
if [ -e "$obsID_list" ]; then rm "$obsID_list"; fi 
touch "$obsID_list"
if [ -e "$filter_list" ]; then rm "$filter_list"; fi
touch "$filter_list"
if [ -e "$std2_files" ]; then rm "$std2_files"; fi; touch "$std2_files"
if [ -e "$evt_bkgd_list" ]; then rm "$evt_bkgd_list"; fi; touch "$evt_bkgd_list"

echo -e "Starting script 'rxte_reduce_data.sh'\n" > $progress_log

num_newfiles=$(wc -l < $newfilelist)
current_file_num=1
echo "Number of new files: $num_newfiles"

for newfile in $(cat $newfilelist); do  ## For each newfile listed in newfilelist
	
	echo "ObsID $current_file_num/$num_newfiles" >> $progress_log
	obs_dir=`dirname ${newfile}`  ## Where the observation is stored
	echo "obs_dir = $obs_dir"

	length_obs_dir=${#obs_dir}  ## Number of characters in obs_dir
	
	if (( $length_obs_dir == 53 )); then
		x1=$((length_obs_dir-13))  ## Character index bound for cutting obsID
	elif (( $length_obs_dir == 54 )); then
		x1=$((length_obs_dir-14))  ## Character index bound for cutting obsID
	else
		x1=13
		echo -e "\tERROR: Length of observing directory name is unexpected. Exiting."
		echo -e "\tERROR: Length of observing directory name is unexpected. Exiting." >> $progress_log
		exit
	fi
	
	## Slice the directory name to get the obsID and propID
	obsID=$(echo $obs_dir | cut -c${x1}-${length_obs_dir})  ## Observation ID
	x2=$((x1-7))  ## Character index bound for cutting propID
	x3=$((x1-2))  ## Character index bound for cutting propID
	propID=$(echo $obs_dir | cut -c${x2}-${x3})  ## Proposal ID
	
	echo "propID = $propID"
	echo "obsID = $obsID"
	echo "$obsID" >> $obsID_list
	echo "Starting run for obsID=$obsID" >> $progress_log
	
	out_dir="$out_dir_prefix/$propID/$obsID"  ## Where you want your output to 
											  ## go for each observation 
											  ## (filter files, reduced data 
											  ## products)
	echo "out_dir = $out_dir"
	## If the output directory doesn't already exist, make it
	if test ! -d "$out_dir"; then mkdir -p "$out_dir"; fi
	
# 	fileroot="$out_dir/${target_name}_${obsID}"  ## The root name of all files!
# 	echo "fileroot = $fileroot" >> $progress_log
	filter_file="$out_dir/filter.xfl"
	if [ ! -e "$filter_file" ] ; then  ## If the filter file doesn't exist
		echo "Making a filter file."
		## Running xtefilt to make the filter file
# 		xtefilt -a "$list_dir"/appid.lst \
# 			-o $obsID \
# 			-p "$obs_dir" \
# 			-t 16 \
# 			-f "${filter_file%.*}" \
# 			-c   
		
		if [ ! -e "$filter_file" ]; then  ## Filter file wasn't made; Give error
			echo -e "\tERROR: $filter_file not made! Exiting."
			echo -e "\tERROR: $filter_file not made! Exiting." >> $progress_log
			exit
		fi
		
		echo "Filter file made." >> $progress_log
		echo "filter_file = $filter_file"
	
	fi  ## End of 'if filter file wasn't made'
	echo "$filter_file" >> $filter_list

	
	#######################################################
	## Herding important files into the correct directory.
	#######################################################
	
	## Herding the std2 files into the right directory
# 	npca=`ls "$obs_dir"/pca/ | grep -c FS4a`
# 	echo "npca = $npca"
# 	
# 	if (( $npca == 0 )); then  ## npca = 0; Give error
# 		echo -e "\tERROR: $out_dir/std2.pca not made! Exiting."
# 		echo -e "\tERROR: $out_dir/std2.pca not made! Exiting." >> $progress_log
# 		exit
# 	fi
# 			
# 	m=1
# 	for std2file in $(ls "$obs_dir"/pca/FS4a*); do  ## For each FS4a (std 2) file
# 	
# 		echo "std2file = $std2file"
# 		echo "m = $m"
# 		
# 		if [ ${std2file##*.} == gz ]; then  ## If it's gzipped
# 			cp $std2file "$out_dir/std2_${m}".pca.gz
# 		else  ## if it doesn't end in gz
# 			cp $std2file "$out_dir/std2_${m}".pca
# 		fi
# 		
# 		(( m++ ))
# 		echo "$out_dir/std2_${m}.pca" >> $std2_files
# 		
# 	done  ## End for-loop through each FS4a file
# 	
# 	
# 	## Herding the std1b files in to the right directory
# 	mpca=`ls "$obs_dir"/pca/ | grep -c FS46`
# 	echo "mpca = $mpca"
# 	
# 	if (( $mpca == 0 )); then  ## mpca = 0; Give error
# 		echo -e "\tERROR: $out_dir/vle.pca not made! Exiting."
# 		echo -e "\tERROR: $out_dir/vle.pca not made! Exiting." >> $progress_log
# 		exit
# 	fi
# 	
# 	m=1
# 	for std1bfile in $(ls "$obs_dir"/pca/FS46*); do  ## For each FS46 (std 1b) file
# 		
# 		echo "std1bfile = $std1bfile"
# 		echo "m = $m"
# 		
# 		if [ ${std1bfile##*.} == gz ]; then  ## If it's gzipped
# 			cp $std1bfile "$out_dir/vle_${m}".pca.gz
# 		else  ## If it doesn't end in gz
# 			cp $std1bfile "$out_dir/vle_${m}".pca
# 		fi
# 		
# 		(( m++ ))
# 		
# 	done  ## End for-loop through each FS46 file
# 	
# 	## Herding the event mode files into the right directory
# 	echo "$obs_dir/pca"
# 	lpca=`ls "$obs_dir"/pca/ | grep -c FS4f`
# 	echo "lpca = $lpca"
# 
# 	if (( $lpca == 0 )); then  ## lpca = 0; Give error
# 		echo -e "\tERROR: $out_dir/evt.pca not made! Exiting."
# 		echo -e "\tERROR: $out_dir/evt.pca not made! Exiting." >> $progress_log
# 		exit
# 	fi
# 
# 	m=1
# 	for eventfile in $(ls "$obs_dir"/pca/FS4f*); do  ## For each FS4f (event mode) file
# 
# 		echo "eventfile = $eventfile"
# 		echo "m = $m"
# 
# 		if [ ${eventfile##*.} == gz ]; then  ## If it's gzipped
# 			cp $eventfile "$out_dir/evt_${m}".pca.gz
# 		else  ## if it doesn't end in gz
# 			cp $eventfile "$out_dir/evt_${m}".pca
# 		fi
# 
# 		(( m++ ))
# 
# 	done  ## End for-loop through each FS4f file
# 
# 	gunzip -f "$out_dir"/*.gz
					
	if [ -e $dump_file ]; then rm -f $dump_file; fi
	
	
	#################################################
	## Now making the std2 GTI and background files.
	#################################################
		
	gti_file="$out_dir/gti_file.gti"
	echo "gti_file = $gti_file"
	echo "Now making GTI and std2 background"

	if [ -e $out_dir/gti.lst ]; then rm $out_dir/gti.lst; fi

	if [ -e $gti_file ]; then rm $gti_file; fi
	
	bkgd_model="$list_dir/pca_bkgd_cmbrightvle_eMv20051128.mdl"  ## good for > 40 counts/sec/pcu
	# 	bkgd_model="$list_dir/pca_bkgd_cmfaintl7_eMv20051128.mdl"  ## good for < 40 counts/sec/pcu
	saa_history="$list_dir/pca_saa_history"
	filtex="(PCU2_ON==1)&&(PCU0_ON==1)&&(elv>10)&&(offset<0.02)&&(VpX1LCntPcu2<=150)&&(VpX1RCntPcu2<=150)"
	# filtex="(PCU2_ON==1)&&(PCU0_ON==1)&&(elv>10)&&(offset<0.02)"
	# filtex="(PCU2_ON==1)&&(PCU0_ON==1)&&(elv>10)&&(offset<0.02)&&(VpX1LCntPcu2>=100)&&(VpX1RCntPcu2>=100)"
	# echo "filtex = $filtex"
	bin_loc=$(python -c "from tools import get_key_val; print get_key_val('$filter_file', 0, 'TIMEPIXR')")
	echo "TIMEPIXR = $bin_loc"
# 	
# 	if (( bin_loc == 0 )); then
# 	# 	echo "In here 1"
# 		maketime infile=$filter_file outfile=$gti_file expr=$filtex name=NAME \
# 			value=VALUE time=Time compact=no clobber=yes prefr=0.0 postfr=1.0
# 	elif (( bin_loc == 1 )); then
# 	# 	echo "In here 2"
# 		maketime infile=$filter_file outfile=$gti_file expr=$filtex name=NAME \
# 			value=VALUE time=Time compact=no clobber=yes prefr=1.0 postfr=0.0
# 	else
# 	# 	echo "In here 3"
# 		maketime infile=$filter_file outfile=$gti_file expr=$filtex name=NAME \
# 			value=VALUE time=Time compact=no clobber=yes prefr=0.5 postfr=0.5
# 	fi

	for std2_pca_file in $(ls $out_dir/"std2"*.pca); do
	
		## Use these with standard 1 or 2 data -- don't have gain correction applied.
		std2_bkgd=${std2_pca_file%.*}"_std2.bkgd"
		echo "std2 bkgd file = $std2_bkgd"
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
# 				echo -e "\tERROR: ${std2_bkgd%.*}_bkgd.pha not made."
# 				echo -e "\tERROR: ${std2_bkgd%.*}_bkgd.pha not made." >> $progress_log
# 			fi
# 		else
# 			echo -e "\tERROR: Standard-2 background file not made."
# 			echo -e "\tERROR: Standard-2 background file not made." >> $progress_log
# 		fi
# 		
		
		## These bkgd files are made with the gain correction and full 256 channels,
		## they should be used when data is not good xenon or standard 1 or 2
		## Use this for event-mode data! need to re-bin once i've extracted a spectrum
# 		echo "Making event-mode background."
# 		echo "Making event-mode background." >> $progress_log
		event_bkgd="${std2_pca_file%.*}_evt.bkgd"
		echo "event bkgd file = $event_bkgd"
# 		
# 		pcabackest infile=$std2_pca_file \
# 			outfile=$event_bkgd \
# 			modelfile=$bkgd_model \
# 			filterfile=$filter_file \
# 			layers=yes \
# 			saahfile=$saa_history \
# 			interval=16 \
# 			gaincorr=yes \
# 			gcorrfile=caldb \
# 			fullspec=yes \
# 			clobber=yes
# 
# 		if [ -e "$event_bkgd" ]; then
# 			cols="$out_dir/std2_pcu2_cols.pcu"
# 			cat "$list_dir"/std2_pcu2_cols.lst > "$cols"
# 			
# 			## Extract a spectrum from the event mode background file
# 			saextrct lcbinarray=10000000 \
# 				maxmiss=200 \
# 				infile=$event_bkgd \
# 				gtiorfile=- \
# 				gtiandfile="$gti_file" \
# 				outroot="${event_bkgd%.*}_bkgd" \
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
# 			if [ ! -e "${event_bkgd%.*}_bkgd.pha" ]; then
# 				echo -e "\tERROR: ${event_bkgd%.*}_bkgd.pha not made."
# 				echo -e "\tERROR: ${event_bkgd%.*}_bkgd.pha not made." >> $progress_log
# 			fi
# 			echo "${event_bkgd%.*}_bkgd.pha" >> $evt_bkgd_list
# 		else
# 			echo -e "\tERROR: Event-mode background file not made. Exiting."
# 			echo -e "\tERROR: Event-mode background file not made. Exiting." >> $progress_log
# 			exit
# 		fi
			
		## Good Xenon bkgd files are made with the full 256 channels but no gain
	    ## correction
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

	done
	echo "Finished making GTI and std2 background." >> $progress_log
	
# 	#######################################################
# 	## Start of extracting Standard 2 and Standard 1b data
# 	#######################################################
#  	
# 	sa_cols="$out_dir/std2_cols.pcu"
# 	echo "sa_cols = $sa_cols"
# 	
# 	if [ -e "$out_dir/std2.lst" ]; then rm -f "$out_dir/std2.lst"; fi
# 	ls $out_dir/std2*.pca > "$out_dir/std2.lst"
# 	
# 	cat "$list_dir"/std2_pcu2_cols.lst > "$sa_cols"
# 	
# 	echo "Extracting std2 data" >> $progress_log
# 	## Getting count rates from std2 files
# 	saextrct lcbinarray=10000000 \
# 		maxmiss=200 \
# 		infile=@"$out_dir/std2.lst" \
# 		gtiorfile=- \
# 		gtiandfile="$gti_file" \
# 		outroot="$out_dir/std2" \
# 		columns=@"$sa_cols" \
# 		accumulate=ONE \
# 		timecol=TIME \
# 		binsz=16 \
# 		mfracexp=INDEF \
# 		printmode=SPECTRUM \
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
# 	if [ -e $dump_file ]; then rm -f $dump_file; fi
# 	
# 	if [ ! -e "$out_dir/std2.pha" ]; then
# 		echo -e "\tERROR: $out_dir/std2.pha not made!"
# 		echo -e "\tERROR: $out_dir/std2.pha not made!" >> $progress_log
# 	fi  ## End 'if $out_dir/std2.pha files not made', i.e. if saextrct failed
	
# 	ls $out_dir/vle*.pca > "$out_dir/vle.lst"
# 	## Get the VLE rates from std1b files
# 	saextrct lcbinarray=10000000 \
# 		maxmiss=200 \
# 		infile=@"$out_dir/vle.lst" \
# 		gtiorfile=APPLY \
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
# 	if [ -e $dump_file ] ; then rm -f $dump_file; fi
# 	
# 	echo "SAEXTRCT finished"
# 	echo "SAEXTRCT finished" >> $progress_log
# 
# 
# 	#####################################################
# 	## Start of extracting time-resolved event-mode data
# 	#####################################################
# 
# 	if [ -e "$out_dir/evt.lst" ]; then rm -f "$out_dir/evt.lst"; fi
# 	ls $out_dir/evt*.pca > "$out_dir/evt.lst"
# 	if [ -e "$out_dir/evt_1.pca" ]; then
# 		time_res=$(python "$script_dir"/get_keyword.py "$out_dir/evt_1.pca" 1 TIMEDEL 1)
# 		echo "Time resolution of raw data = $time_res s" >> $progress_log
# 	fi					
# 	echo "$out_dir/evt.lst" >> $progress_log
# # 	echo "'GTI and' file: $gti_file"
# # 	echo "$out_dir/event"
# # 	echo @"event_files"
# 	echo "Extracting event data" >> $progress_log
# 	## Extract time-resolved event-mode data
# 	## Don't put *any* spaces after the \ slashes. TGIF.
# 	## Using bitfile_evt_PCU2 for only PCU2 photons
# 	seextrct infile=@"$out_dir/evt.lst" \
# 		maxmiss=INDEF \
# 		gtiorfile=- \
# 		gtiandfile="$gti_file" \
# 		outroot="$out_dir/event" \
# 		bitfile="$list_dir"/bitfile_evt_PCU2 \
# 		timecol="TIME" \
# 		columns="Event" \
# 		multiple=yes \
# 		binsz=1 \
# 		printmode=BOTH \
# 		lcmode=RATE \
# 		spmode=SUM \
# 		timemin=INDEF \
# 		timemax=INDEF \
# 		timeint=INDEF \
# 		chmin=INDEF \
# 		chmax=INDEF \
# 		chint=INDEF \
# 		chbin=INDEF \
# 		mode=ql
# 	
# 	if [ ! -e "$out_dir/event.lc" ] ; then
# 		echo -e "\tERROR: $out_dir/event.lc not made!"
# 		echo -e "\tERROR: $out_dir/event.lc not made!" >> $progress_log
# 	fi  ## End 'if $out_dir/event.lc files not made', i.e. if saextrct failed
# 	if [ ! -e "$out_dir/event.pha" ] ; then
# 		echo -e "\tERROR: $out_dir/event.pha not made!"
# 		echo -e "\tERROR: $out_dir/event.pha not made!" >> $progress_log
# 	fi  ## End 'if $out_dir/event.lc files not made', i.e. if 
# 	
# 	echo "SEEXTRCT finished"
# 	echo "SEEXTRCT finished" >> $progress_log
# 	
# 	## Copying approximated quaternion file for pcarsp
# 	raw_quaternions=$(ls "$data_dir/$propID/$obsID"/acs/FH0e*)
# 	quaternions="$out_dir/appx_quat"
# 	echo "Raw quaternions = $raw_quaternions"
# 	echo "Quaternions = $quaternions.fits"
# 	if [ ${raw_quaternions##*.} == gz ]; then  ## If it's gzipped
# 		echo "Gzipped."
# 		cp "$raw_quaternions" "$quaternions".fits.gz
# 		gunzip -f "$quaternions".fits.gz
# 	else  ## if it doesn't end in gz
# 		echo "Not gzipped"
# 		cp "$raw_quaternions" "$quaternions".fits
# 	fi					
					
	echo -e "Finished run for obsID=$obsID \n" >> $progress_log
	(( current_file_num++ ))
	
done  ## End for-loop of each newfile in newfilelist

echo -e "Finished individual obsIDs.\n"
echo -e "Finished individual obsIDs.\n" >> $progress_log

###############################################################################
## Now making a filter, gti, std2 spectrum, and adding event-mode background 
## spectra for ALL std2 files. Event-mode background will still need to be 
## rebinned!
###############################################################################

out_dir="$out_dir_prefix/$propID"

## Sort filter files from above chronologically
# filters_ordered="$out_dir/all_filters_ordered.lst"
# # echo "$filter_list"
# python -c "from tools import time_ordered_list; time_ordered_list('$filter_list')" > $filters_ordered
filter_file="$out_dir/all.xfl"
gti_file="$out_dir/all.gti"
# 
# ## Merge the filter files into one big one
# fmerge infiles=@"$filters_ordered" \
# 	outfile="$filter_file" \
# 	columns=- \
# 	copyprime=yes \
# 	lastkey=TSTOP \
# 	clobber=yes
# 
# if [ ! -e "$filter_file" ] ; then
# 	echo -e "\tERROR: $filter_file not made! Exiting."
# 	echo -e "\tERROR: $filter_file not made! Exiting." >> $progress_log
# 	exit
# fi
# 
# ## Make a GTI from the merged filter file for all the obsIDs
# if (( bin_loc == 0 )); then
# # 	echo "In here 1"
# 	maketime infile=$filter_file outfile=$gti_file expr=$filtex name=NAME \
# 		value=VALUE time=Time compact=no clobber=yes prefr=0.0 postfr=1.0
# elif (( bin_loc == 1 )); then
# # 	echo "In here 2"
# 	maketime infile=$filter_file outfile=$gti_file expr=$filtex name=NAME \
# 		value=VALUE time=Time compact=no clobber=yes prefr=1.0 postfr=0.0
# else
# # 	echo "In here 3"
# 	maketime infile=$filter_file outfile=$gti_file expr=$filtex name=NAME \
# 		value=VALUE time=Time compact=no clobber=yes prefr=0.5 postfr=0.5
# fi
# 
# if [ ! -e "$gti_file" ] ; then
# 	echo -e "\tERROR: $gti_file not made! Exiting."
# 	echo -e "\tERROR: $gti_file not made! Exiting." >> $progress_log
# 	exit
# fi

all_evt="$out_dir/all_evt.pha"

# ## Make a mean event-mode spectrum
# se_list="$list_dir/$propID_all_evt.lst"
# ls $out_dir/*/evt*.pca > $se_list
# echo "Extracting MEAN evt spectrum"
# echo "Extracting MEAN evt spectrum" >> $progress_log
# 
# seextrct infile=@"$se_list" \
# 	maxmiss=INDEF \
# 	gtiorfile=- \
# 	gtiandfile="$gti_file" \
# 	outroot="${all_evt%.*}" \
# 	bitfile="$list_dir"/bitfile_evt_PCU2 \
# 	timecol="TIME" \
# 	columns="Event" \
# 	multiple=yes \
# 	binsz=1 \
# 	printmode=SPECTRUM \
# 	lcmode=RATE \
# 	spmode=SUM \
# 	timemin=INDEF \
# 	timemax=INDEF \
# 	timeint=INDEF \
# 	chmin=INDEF \
# 	chmax=INDEF \
# 	chint=INDEF \
# 	chbin=INDEF \
# 	mode=ql
# 
# if [ ! -e "$all_evt" ] ; then
# 	echo -e "\tERROR: $all_evt not made! Exiting."
# 	echo -e "\tERROR: $all_evt not made! Exiting." >> $progress_log
# fi  ## End 'if $all_evt not made', i.e. if seextrct failed
# 


## Make a mean standard-2 spectrum
# sa_list="$list_dir/$propID_all_std2.lst"
# ls $out_dir/*/std2*.pha > $sa_list
# # cols="$out_dir/std2_pcu2_cols.pcu"
# # cat "$list_dir"/std2_pcu2_cols.lst > "$cols"
# # 
# # echo "Extracting MEAN std2 pcu 2 data"
# echo "Extracting MEAN std2 pcu 2 data" >> $progress_log
# all_std2="$out_dir/all_std2.pha"
# ## Getting count rates from std2 files
# saextrct lcbinarray=10000000 \
# 	maxmiss=200 \
# 	infile=@"$sa_list" \
# 	gtiorfile=- \
# 	gtiandfile="$gti_file" \
# 	outroot="${all_std2%.*}" \
# 	columns=@"$cols" \
# 	accumulate=ONE \
# 	timecol=TIME \
# 	binsz=16 \
# 	mfracexp=INDEF \
# 	printmode=BOTH \
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
# if [ -e $dump_file ] ; then rm -f $dump_file; fi
# 
# if [ ! -e "${all_std2%.*}.lc" ] ; then
# 	echo -e "\tERROR: ${all_std2%.*}.lc not made!"
# 	echo -e "\tERROR: ${all_std2%.*}.lc not made!" >> $progress_log
# fi  ## End 'if ${all_std2%.*}.lc not made', i.e. if saextrct failed
# 
# if [ ! -e "$all_std2" ] ; then
# 	echo -e "\tERROR: $all_std2 not made! Exiting."
# 	echo -e "\tERROR: $all_std2 not made! Exiting." >> $progress_log
# 	exit
# fi  ## End 'if $all_std2 not made', i.e. if saextrct failed


# ## Adding the extracted event-mode background spectra.

"$script_dir"/event_mode_bkgd.sh "$propID" "$out_dir" "$list_dir" "$all_evt" "$filter_file"


# cp "$evt_bkgd_list" "$out_dir/all_event_bkgd.lst"
# all_evt_bkgd="$out_dir/evt_bkgd_notbinned"
# 
# bkgd_list="$list_dir/$propID_all_bkgd.lst"
# 
# 
# # ls $out_dir/*/std2.pha > $bkgd_list
# echo "$out_dir"
# ls $out_dir/*/*_evt_bkgd.pha > $bkgd_list
# cd "$out_dir"
# 
# ## This is a work-around. Should probably write my own script so that I can
# ## add up more than 35 pha files!! Generally, need to do this part by hand.
# 
# # if [ ! -e "$all_evt_bkgd.pha" ]; then
# 	## If there's only one event file, don't need to add bkgd spectra. 
# 	## If not, add them.
# 	if (( $(wc -l < $evt_bkgd_list) == 1 )) ; then
# 	
# 		only_evt_bkgd_pha=$(cat $evt_bkgd_list)
# 		echo "$only_evt_bkgd_pha"
# 		cp "$only_evt_bkgd_pha" "$all_evt_bkgd.pha"
# 		
# 	else
# 		asdir="./tmp_addspec"; mkdir "$asdir"; cd "$asdir"
# 		as_sums="addspec_listofsums.lst"
# 		if [ -e "$as_sums" ]; then rm "$as_sums"; fi; touch "$as_sums"
# 		i=1; j=1
# 		as_list="addspec_list_${i}.lst"
# 		if [ -e "$as_list" ]; then rm "$as_list"; fi; touch "$as_list"
# 		
# 		## addspec only allows to sum ~35 files at ones. So I break the files 
# 		## into groups of 30, sum them, and then at the end I sum each of those
# 		## sub-sums to get my total background spectrum.
# 		
# 		for item in $(cat "$bkgd_list"); do
# 			cp $item "./${j}_"$(basename $item)
# 			echo "${j}_$(basename $item)"
# 			echo "${j}_$(basename $item)" >> "$as_list"
# 			
# 			if (( j % 30 == 0 )) ; then 
# 				echo -e "\ti = $i"
# 				temp_evt_bkgd="temp_evt_bkgd_${i}"
# 				if [ -e "$temp_evt_bkgd.pha" ]; then rm "$temp_evt_bkgd.pha"; fi
# 				open "$as_list"
# 	
# 				addspec infil="$as_list" \
# 					outfil="$temp_evt_bkgd" \
# 					qaddrmf=no \
# 					qsubback=no \
# 					clobber=no
# 				echo "$temp_evt_bkgd.pha" >> $as_sums
# 				(( i+=1 ))
# 				as_list="addspec_list_${i}.lst"
# 				if [ -e "$as_list" ]; then rm "$as_list"; fi; touch "$as_list"
# 			fi
# # 			echo "j = $j"
# 			(( j+=1 ))
# 
# 		done
# 		
# 		## Doing the last leg (since it doesn't get done otherwise)
# 		if (( j % 10 != 0 )); then
# 			echo -e "\ti = $i"
# 			temp_evt_bkgd="temp_evt_bkgd_${i}"
# 			if [ -e "$temp_evt_bkgd.pha" ]; then rm "$temp_evt_bkgd.pha"; fi
# 			open "$as_list"
# 
# 			addspec infil="$as_list" \
# 				outfil="$temp_evt_bkgd" \
# 				qaddrmf=no \
# 				qsubback=no \
# 				clobber=no
# 			echo "$temp_evt_bkgd.pha" >> $as_sums
# 		fi
# 		
# 		## Now summing the sum groups of bkgd pha files
# 		temp_evt_bkgd="temp_evt_bkgd_total"
# 		if [ -e "$temp_evt_bkgd.pha" ]; then rm "$temp_evt_bkgd.pha"; fi
# 		open "$as_sums"
# 		addspec infil="$as_sums" \
# 			outfil="$temp_evt_bkgd" \
# 			qaddrmf=no \
# 			qsubback=no \
# 			clobber=no
# 	
# 		if [ -e "$temp_evt_bkgd.pha" ]; then
# 			mv "$temp_evt_bkgd.pha" "$all_evt_bkgd.pha"
# 		else
# 			echo -e "\tERROR: addspec failed."
# 		fi
# 		
# 		cd "$out_dir"
# 		rm -rf "$asdir"
# 	fi
# # fi
# 
# if [ ! -e "$all_evt_bkgd.pha" ]; then
# 	echo -e "\tERROR: $all_evt_bkgd.pha not created."
# 	echo -e "\tERROR: $all_evt_bkgd.pha not created." >> $progress_log
# fi
# 
# echo "Background spectrum: $all_evt_bkgd.pha"
# 
# rsp_dump_file="rsp_matrix_dump.dat"
# rsp_matrix="$out_dir/PCU2.rsp"
# 
# ## Making response matrix
# if [ -e "$rsp_matrix" ]; then
# 	echo "$rsp_matrix already exists."
# elif [ -e "$all_evt" ]; then
# 	pcarsp -f "$all_evt" -a "$filter_file" -l all -j y -p 2 -m n -n "$rsp_matrix" -z > $rsp_dump_file
# # 	pcarsp -f "$all_evt" -a "$filter_file" -l all -j y -p 2 -m n -n "$rsp_matrix" -z
# else
# 	echo -e "\tERROR: $all_evt does NOT exist. pcarsp was NOT run."
# fi
# 
# rb_event_bkgd="$out_dir/evt_bkgd_rebinned.pha"
# 
# if [ -e "$all_evt_bkgd.pha" ] && [ -e "$out_dir/chan.txt" ] ; then
# 	rbnpha infile="$all_evt_bkgd.pha" \
# 		outfile="$rb_event_bkgd" \
# 		binfile="$out_dir/chan.txt" \
# 		chatter=4 \
# 		clobber=yes
# else
# 	echo -e "\tERROR: $all_evt_bkgd.pha and/or $out_dir/chan.txt do NOT exist. rbnpha was NOT run."
# fi


cd "$current_dir"
echo "Finished script ‘rxte_reduce_data.sh'" >> $progress_log
echo -e "\nFinished script 'rxte_reduce_data.sh'.\n"

