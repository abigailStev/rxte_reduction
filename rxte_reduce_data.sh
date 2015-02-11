#! /bin/bash

###############################################################################
##
## Extract and reduce RXTE PCA data.
##
## Example call: 
## ./rxte_reduce_data.sh ./newfiles.lst ./obsIDs.lst ObjectName > run.log
## run.log has the full print outs. The file progress.log is a more concise way
## to keep track of progress.
##
## Inspired by G. Lamer (gl@astro.soton.ac.uk)'s script 'xrbgetprod'
## 
## Notes: heainit needs to already be running!
## 
## Abigail Stevens, A.L.Stevens@uva.nl, 2014-2015 
##
###############################################################################

## Make sure the input arguments are ok
if (( $# != 3 )); then
    echo -e "\t\tUsage: ./rxte_reduce_data.sh <newfiles.lst> <obsIDs.lst> <prefix>"
    exit
fi

## If heainit isn't running, start it
if (( $(echo $DYLD_LIBRARY_PATH | grep heasoft | wc -l) < 1 )); then
	. $HEADAS/headas-init.sh
fi

newfilelist=$1  ## File with list of new files; with extension xdf, from xtescan or interactive xdf
obsID_list=$2  ## File with list of obsIDs, to be written to
prefix=$3  ## Prefix of directories and files (either proposal ID or object nickname)

home_dir=$(ls -d ~)  ## The home directory of this machine; the -d flag is 
					 ## extremely important here
data_dir="$home_dir/Data/RXTE"  ## Data directory
script_dir="$home_dir/Dropbox/Research/rxte_reduce"  ## Directory containing the
													 ## data reduction scripts
little_scripts="$home_dir/Dropbox/Scripts"  ## Contains python helper scripts
list_dir="$home_dir/Dropbox/Lists"  ## A folder of lists; tells which files 
									## we're using
current_dir=$(pwd)  ## The current directory
# out_dir_prefix="$home_dir/Dropbox/Research/Data"  ## Prefix of output 
													## directory (for Aeolus)
out_dir_prefix="$home_dir/Reduced_data"  ## Prefix of output directory (for Hera)
dump_file=dum.dat  ## Name of dumping file for intermediary steps
progress_log="$current_dir/progress.log"  ## File with concise description of 
										  ## this script's progress
# prefix="xx"  ## Need to declare this here so that it can be used later
filter_list="$list_dir/tmp_all_filters.lst"  ## This gets changed later on
evt_bkgd_list="$list_dir/tmp_evt_bkgd.lst"
se_list="$list_dir/${prefix}_all_evt.lst"
sa_list="$list_dir/${prefix}_all_std2.lst"

###############################################################################

echo -e "Starting script 'rxte_reduce_data.sh'\n" > $progress_log

if [ ! -e "$newfilelist" ]; then
	echo -e "\tERROR: $newfilelist does not exist. Exiting."
	echo -e "\tERROR: $newfilelist does not exist. Exiting." >> $progress_log
	exit
fi

echo "data_dir = $data_dir"
echo "current_dir = $current_dir"
echo "obsID list = $obsID_list"
echo "new file list in desired data mode = $newfilelist"

if [ -e "$obsID_list" ]; then rm "$obsID_list"; fi; touch "$obsID_list"
if [ -e "$filter_list" ]; then rm "$filter_list"; fi; touch "$filter_list"
if [ -e "$evt_bkgd_list" ]; then rm "$evt_bkgd_list"; fi; touch "$evt_bkgd_list"
if [ -e "$se_list" ]; then rm "$se_list"; fi; touch "$se_list"
if [ -e "$sa_list" ]; then rm "$sa_list"; fi; touch "$sa_list"

echo "prefix = ${prefix}"

num_newfiles=$( wc -l < $newfilelist )
current_file_num=1
echo "Number of new files: $num_newfiles" | xargs

###############################################################################
## Looping through each 'newfile' in 'newfilelist'
###############################################################################

for newfile in $( cat $newfilelist ); do
	
	echo "ObsID $current_file_num /$num_newfiles" | xargs >> $progress_log  ## xargs trims the leading whitespace from $num_newfiles
	obs_dir=$( dirname `dirname ${newfile}` )  ## Where the observation is stored
	echo "obs_dir = $obs_dir"
	
	IFS='/' read -a directories <<< "$newfile"
	obsID="${directories[6]}"
	echo "obsID = $obsID"
	echo "$obsID" >> $obsID_list
	echo "Starting run for obsID=$obsID" >> $progress_log

	out_dir="${out_dir_prefix}/${prefix}/$obsID"  ## Where you want your output 
											  	  ## to go for each observation 
											  	  ## (filter files, reduced data 
											  	  ## products)
	echo "out_dir = $out_dir"
	## If the output directory doesn't already exist, make it
	if test ! -d "$out_dir"; then mkdir -p "$out_dir"; fi
	
	## Making a filter file
	filter_file="$out_dir/filter.xfl"
	if [ ! -e "$filter_file" ] ; then  ## If the filter file doesn't exist
		echo "Making a filter file."
		## Running xtefilt to make the filter file
		xtefilt -a "$list_dir"/appid.lst \
			-o $obsID \
			-p "$obs_dir" \
			-t 16 \
			-f "${filter_file%.*}" \
			-c   
		
		if [ ! -e "$filter_file" ]; then  ## Filter file wasn't made; Give error
			echo -e "\tERROR: Filter file not made!"
			echo -e "\tERROR: Filter file not made!" >> $progress_log
			continue
		fi
		
		echo "Filter file made." >> $progress_log
		echo "filter_file = $filter_file"
	
	fi  ## End of 'if filter file wasn't made'
	echo "$filter_file" >> $filter_list

	
	#######################################################
	## Herding important files into the correct directory.
	#######################################################
	
	## Herding the std2 files into the right directory
	num_std2=$( ls "$obs_dir"/pca/ | grep -c FS4a )
	
	if (( $num_std2 == 0 )); then  ## num_std2 = 0; Give error
		echo -e "\tNo Standard2 files for this obsID."
		echo -e "\tNo Standard2 files for this obsID." >> $progress_log
		continue
	fi
			
	m=1
	## For each FS4a (Standard-2) file
	for std2file in $( ls "$obs_dir"/pca/FS4a* ); do 
	
		echo "std2file = $std2file"
		echo "m = $m"
		new_std2="$out_dir/std2_${m}".pca
		if [ ${std2file##*.} == gz ]; then  ## If it's gzipped
			cp $std2file "$new_std2".gz
		else  ## if it doesn't end in gz
			cp $std2file "$new_std2"
		fi
		
		(( m++ ))
		echo "$new_std2" >> $sa_list
		
	done  ## End for-loop through each Std2 file

	## Herding the event mode files into the right directory
	## Get the datamode prefix from newfile in newfilelist 
	## (made in xtescan or interactive xdf)
	mode_prefix=$( echo `basename $newfile` | cut -c 1-4 ) 
	num_evt=$( ls "$obs_dir"/pca/ | grep -c "${mode_prefix}" ) 

	if (( $num_evt == 0 )); then  ## num_evt = 0; Give error
		echo -e "\tNo event-mode files for this obsID."
		echo -e "\tNo event-mode files for this obsID." >> $progress_log
		continue
	fi

	m=1
	## For each event-mode file
	for eventfile in $( ls "$obs_dir"/pca/"${mode_prefix}"* ); do  

		echo "eventfile = $eventfile"
		echo "m = $m"
		new_evt="$out_dir/evt_${m}".pca
		
		if [ ${eventfile##*.} == gz ]; then  ## If it's gzipped
			cp $eventfile "$new_evt".gz
		else  ## if it doesn't end in gz
			cp $eventfile "$new_evt"
		fi
		echo "$new_evt" >> $se_list
		(( m++ ))

	done  ## End for-loop through each event-mode file

	gunzip -f "$out_dir"/*.gz
					
	if [ -e $dump_file ]; then rm -f $dump_file; fi
	
	
	#############################################
	## Now making the GTI and background files.
	#############################################
	
# 	filtex="(PCU2_ON==1)&&(PCU0_ON==1)&&(elv>10)&&(offset<0.02)&&(VpX1LCntPcu2<=150)&&(VpX1RCntPcu2<=150)"  ## For saxj1808, to get rid of TBOs
# 	filtex="(PCU2_ON==1)&&(PCU0_ON==1)&&(elv>10)&&(offset<0.02)"  ## For black holes
	filtex="(PCU2_ON==1)&&(elv>10)&&(offset<0.02)&&(NUM_PCU_ON>=2)"  ## For GX339 QPOs; don't 
													## need to worry about time
													## since saa as it's not a 
													## very bright source
# 	filtex="(PCU2_ON==1)&&(PCU0_ON==1)&&(elv>10)&&(offset<0.02)&&(VpX1LCntPcu2>=100)&&(VpX1RCntPcu2>=100)"

# 	"$script_dir"/gti_and_bkgd.sh "$out_dir" "$filtex" "$progress_log" "$evt_bkgd_list"
	
	##########################################################
	## Built-in extraction of Standard-2f and event-mode data
	##########################################################
 	
# 	"$script_dir"/indiv_extract.sh "$out_dir" "$progress_log" "$list_dir"		


	echo -e "Finished run for obsID=$obsID \n"				
	echo -e "Finished run for obsID=$obsID \n" >> $progress_log
	(( current_file_num++ ))
	
# 	break
done  ## End for-loop of each newfile in newfilelist
###############################################################################

echo -e "Finished individual obsIDs.\n"
echo -e "Finished individual obsIDs.\n" >> $progress_log

###############################################################################
## Now making a filter, gti, event-mode spectrum, Std2 lightcurve and spectrum, 
## adding event-mode background spectra, re-binning the total event-mode 
## background spectrum, and making a response matrix for ALL obsIDs. 
###############################################################################

out_dir="$out_dir_prefix/${prefix}"

# ## Sort filter files from above chronologically
# filters_ordered="$out_dir/all_filters_ordered.lst"
# python -c "from tools import time_ordered_list; time_ordered_list('$filter_list')" > $filters_ordered
# filter_file="$out_dir/all.xfl"
# gti_file="$out_dir/all.gti"
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
# 	echo -e "\tERROR: fmerge did not work, total filter file not made. Exiting."
# 	echo -e "\tERROR: fmerge did not work, total filter file not made. Exiting." >> $progress_log
# 	exit
# fi
# 
# ##############################################################
# ## Make a GTI from the merged filter file for all the obsIDs
# ##############################################################
# 
# bkgd_model="$list_dir/pca_bkgd_cmbrightvle_eMv20051128.mdl"  ## good for > 40 counts/sec/pcu
# # bkgd_model="$list_dir/pca_bkgd_cmfaintl7_eMv20051128.mdl"  ## good for < 40 counts/sec/pcu
# saa_history="$list_dir/pca_saa_history"
# 
# bin_loc=$(python -c "from tools import get_key_val; print get_key_val('$filter_file', 0, 'TIMEPIXR')")
# if (( bin_loc == 0 )); then
# 	maketime infile=$filter_file outfile=$gti_file expr=$filtex name=NAME \
# 		value=VALUE time=Time compact=no clobber=yes prefr=0.0 postfr=1.0
# elif (( bin_loc == 1 )); then
# 	maketime infile=$filter_file outfile=$gti_file expr=$filtex name=NAME \
# 		value=VALUE time=Time compact=no clobber=yes prefr=1.0 postfr=0.0
# else
# 	echo "Warning: TIMEPIXR is neither 0 nor 1. Setting prefr=postfr=0.5."
# 	echo "Warning: TIMEPIXR is neither 0 nor 1. Setting prefr=postfr=0.5." >> $progress_log
# 	maketime infile=$filter_file outfile=$gti_file expr=$filtex name=NAME \
# 		value=VALUE time=Time compact=no clobber=yes prefr=0.5 postfr=0.5
# fi
# 
# if [ ! -e "$gti_file" ] ; then
# 	echo -e "\tERROR: Total GTI file not made. Exiting."
# 	echo -e "\tERROR: Total GTI file not made. Exiting." >> $progress_log
# 	exit
# fi
# 
# ###################################
# ## Make a mean event-mode spectrum
# ###################################
# 
# echo "Extracting MEAN evt spectrum"
# echo "Extracting MEAN evt spectrum" >> $progress_log
# all_evt="$out_dir/all_evt.pha"
# if (( $(wc -l < $se_list) == 0 )); then
# 	echo -e "\tERROR: No event-mode data files. Cannot run seextrct."
# 	echo -e "\tERROR: No event-mode data files. Cannot run seextrct." >> $progress_log
# else
# 	seextrct infile=@"$se_list" \
# 		maxmiss=INDEF \
# 		gtiorfile=- \
# 		gtiandfile="$gti_file" \
# 		outroot="${all_evt%.*}" \
# 		bitfile="$list_dir"/bitfile_evt_PCU2 \
# 		timecol="TIME" \
# 		columns="Event" \
# 		multiple=yes \
# 		binsz=1 \
# 		printmode=SPECTRUM \
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
# 	if [ ! -e "$all_evt" ] ; then
# 		echo -e "\tERROR: Total event-mode spectrum not made!"
# 		echo -e "\tERROR: Total event-mode spectrum not made!" >> $progress_log
# 	# 	exit
# 	fi  ## End 'if $all_evt not made', i.e. if seextrct failed
# fi
# 
# ###################################
# ## Make a mean standard-2 spectrum
# ###################################
# 
# echo "Extracting MEAN std2 pcu 2 data"
# echo "Extracting MEAN std2 pcu 2 data" >> $progress_log
# all_std2="$out_dir/all_std2.pha"
# cp "$list_dir"/std2_pcu2_cols.lst ./tmp_std2_pcu2_cols.lst
# 
# if (( $(wc -l < $sa_list) == 0 )); then
# 	echo -e "\tERROR: No Standard-2 data files. Cannot run saextrct."
# 	echo -e "\tERROR: No Standard-2 data files. Cannot run saextrct." >> $progress_log
# else
# 	saextrct lcbinarray=10000000 \
# 		maxmiss=200 \
# 		infile=@"$sa_list" \
# 		gtiorfile=- \
# 		gtiandfile="$gti_file" \
# 		outroot="${all_std2%.*}" \
# 		columns=@tmp_std2_pcu2_cols.lst \
# 		accumulate=ONE \
# 		timecol="Time" \
# 		binsz=16 \
# 		mfracexp=INDEF \
# 		printmode=BOTH \
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
# 	if [ ! -e "${all_std2%.*}.lc" ] ; then
# 		echo -e "\tERROR: Total Standard-2 light curve not made!"
# 		echo -e "\tERROR: Total Standard-2 light curve not made!" >> $progress_log
# 	fi  ## End 'if lightcurve not made', i.e. if saextrct failed
# 	if [ ! -e "$all_std2" ] ; then
# 		echo -e "\tERROR: Total Standard-2 spectrum not made!"
# 		echo -e "\tERROR: Total Standard-2 spectrum not made!" >> $progress_log
# # 		exit
# 	fi  ## End 'if spectrum not made', i.e. if saextrct failed
# fi  ## End 'if there are std2 files in $sa_list'
# 
# echo "Done with total extractions."
# 
# ## Deleting the temporary file(s)
# rm tmp_std2_pcu2_cols.lst
# 
# #######################################################
# ## Adding the extracted event-mode background spectra.
# #######################################################
# 
# "$script_dir"/event_mode_bkgd.sh "$out_dir" "$evt_bkgd_list" "$all_evt" "$progress_log"
# 
# ######################################################
# ## Analyzing filter files to see how many PCUs are on
# ######################################################
# 
# # "$script_dir"/analyze_filters.sh "$list_dir/${prefix}_propIDs.lst" "$prefix"
# "$script_dir"/analyze_filters.sh "$obsID_list" "$prefix" >> $progress_log

###############################################################################
## 					All done!
###############################################################################

cd "$current_dir"
echo -e "\nFinished script ‘rxte_reduce_data.sh'" >> $progress_log
echo -e "\nFinished script 'rxte_reduce_data.sh'.\n"

###############################################################################
