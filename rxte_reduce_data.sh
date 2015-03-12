#! /bin/bash

################################################################################
##
## Extract and reduce RXTE PCA data.
##
## Example call: 
## ./rxte_reduce_data.sh ./newfiles.xdf ./obsIDs.lst ObjectName > run.log
## 
## Change the directory names and specifiers before the double '#' row to best
## suit your setup.
## 
## run.log has the full print outs. The file progress.log is a more concise way
## to keep track of progress.
##
## Notes: HEASOFT 6.14 (or higher), bash 3.* and Python 2.7.* (with supporting 
##		  libraries) must be installed in order to run this script. Internet 
##        access is required for most setups of CALDB.
##
## Inspired by/Based on G. Lamer (gl@astro.soton.ac.uk)'s script 'xrbgetprod'
## Written by Abigail Stevens, A.L.Stevens at uva.nl, 2014-2015 
##
################################################################################

## Make sure the input arguments are ok
if (( $# != 3 )); then
    echo -e "\t\tUsage: ./rxte_reduce_data.sh <newfiles.xdf> <obsIDs.lst> <prefix>\n"
    exit
fi

newfilelist=$1  ## File with list of new files; with extension xdf, from xtescan
				## or interactive xdf
obsID_list=$2  ## File with list of obsIDs, to be written to
prefix=$3  ## Prefix of directories and files (either proposal ID or object 
		   ## nickname)
		   
################################################################################

## If heainit isn't running, start it
if (( $(echo $DYLD_LIBRARY_PATH | grep heasoft | wc -l) < 1 )); then
	. $HEADAS/headas-init.sh
fi

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
out_dir_prefix="$home_dir/Reduced_data"  ## Prefix of output directory
## out_dir is set to out_dir_prefix/prefix/obsID below in the big loop
progress_log="$current_dir/progress.log"  ## File with concise description of 
										  ## this script's progress
filter_list="$${out_dir_prefix}/${prefix}/all_filters_ordered.lst"  ## This gets changed later on
evt_bkgd_list="${out_dir_prefix}/${prefix}/all_event_bkgd.lst"
se_list="$list_dir/${prefix}_all_evt.lst"
sa_list="$list_dir/${prefix}_all_std2.lst"


std2pcu2_cols="$list_dir/std2_pcu2_cols.lst"

## The bright bkgd model is good for > 40 counts/sec/pcu
bkgd_model="$list_dir/pca_bkgd_cmbrightvle_eMv20051128.mdl"  
## The faint bkgd model is good for < 40 counts/sec/pcu
# bkgd_model="$list_dir/pca_bkgd_cmfaintl7_eMv20051128.mdl"
saa_history="$list_dir/pca_saa_history"

## For saxj1808, to filter out the thermonuclear bursts
# filtex="(PCU2_ON==1)&&(PCU0_ON==1)&&(elv>10)&&(offset<0.02)&&(VpX1LCntPcu2<=150)&&(VpX1RCntPcu2<=150)"
## For GX339 QPOs; don't need to worry about time_since_saa since it's bright
filtex="(PCU2_ON==1)&&(NUM_PCU_ON>=2)&&(elv>10)&&(offset<0.02)"  
## For j1808-1HzQPO; also use faint background model
# filtex="(PCU2_ON==1)&&(NUM_PCU_ON>=2)&&(elv>10)&&(offset<0.02)&&(VpX1LCntPcu2<=150)&&(VpX1RCntPcu2<=150)&&(TIME_SINCE_SAA>30)&&(ELECTRON2<0.1)"  
## For thermonuclear burst oscillations ONLY
# filtex="(PCU2_ON==1)&&(NUM_PCU_ON>=2)&&(elv>10)&&(offset<0.02)&&(VpX1LCntPcu2>=100)&&(VpX1RCntPcu2>=100)"


################################################################################
################################################################################

echo -e "Starting script 'rxte_reduce_data.sh'\n" > $progress_log

if [ ! -e "$newfilelist" ]; then
	echo -e "\tERROR: $newfilelist does not exist. Exiting."
	echo -e "\tERROR: $newfilelist does not exist. Exiting." >> $progress_log
	exit
fi

echo "Data directory = $data_dir"
echo "Current directory = $current_dir"
echo "ObsID list = $obsID_list"
echo "List of new files in desired data mode = $newfilelist"

if [ ! -d "${out_dir_prefix}/${prefix}" ]; then mkdir "${out_dir_prefix}/${prefix}"; fi
## Re-writing over the obsID list in case not every obsID downloaded has the 
## data mode we're interested in.
if [ -e "$obsID_list" ]; then rm "$obsID_list"; fi; touch "$obsID_list"
if [ -e "$filter_list" ]; then rm "$filter_list"; fi; touch "$filter_list"
if [ -e "$evt_bkgd_list" ]; then rm "$evt_bkgd_list"; fi; touch "$evt_bkgd_list"
if [ -e "$se_list" ]; then rm "$se_list"; fi; touch "$se_list"
if [ -e "$sa_list" ]; then rm "$sa_list"; fi; touch "$sa_list"

echo "Prefix = ${prefix}"

num_newfiles=$( wc -l < $newfilelist )
current_file_num=1
echo "Number of new files: $num_newfiles" | xargs

################################################################################
## Looping through each 'newfile' in 'newfilelist'
################################################################################

for newfile in $( cat $newfilelist ); do
	
	echo "New file $current_file_num /$num_newfiles" | xargs >> $progress_log  
	## xargs trims the leading whitespace from $num_newfiles
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
	
	########################
	## Making a filter file
	########################
	
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
# 		echo "m = $m"
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
# 		echo "m = $m"
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
	
	
	#############################################
	## Now making the GTI and background files.
	#############################################

	gtibkgd_args=()
	gtibkgd_args[0]="$list_dir"
	gtibkgd_args[1]="$script_dir"
	gtibkgd_args[2]="$out_dir"
	gtibkgd_args[3]="$progress_log"
	gtibkgd_args[4]="$filtex"
	gtibkgd_args[5]="$bkgd_model"
	gtibkgd_args[6]="$saa_history"
	gtibkgd_args[7]="$std2pcu2_cols"
	gtibkgd_args[8]="$evt_bkgd_list"

	echo ./gti_and_bkgd.sh "${gtibkgd_args[@]}"
	"$script_dir"/gti_and_bkgd.sh "${gtibkgd_args[@]}"
	
	echo "EVT BKGD LIST = $evt_bkgd_list"

	##########################################################
	## Built-in extraction of Standard-2f and event-mode data
	##########################################################
	
 	echo ./indiv_extract.sh "$out_dir" "$progress_log"
# 	"$script_dir"/indiv_extract.sh "$out_dir" "$progress_log"


	echo -e "Finished run for obsID=$obsID \n"				
	echo -e "Finished run for obsID=$obsID \n" >> $progress_log
	(( current_file_num++ ))
	
# 	break
done  ## End for-loop of each newfile in newfilelist
################################################################################

echo -e "Finished individual obsIDs.\n"
echo -e "Finished individual obsIDs.\n" >> $progress_log

alltogether_args=()
alltogether_args[0]="$list_dir"
alltogether_args[1]="$script_dir"
alltogether_args[2]="$prefix"
alltogether_args[3]="$progress_log"
alltogether_args[4]="$obsID_list"
alltogether_args[5]="$out_dir_prefix"
alltogether_args[6]="$filter_list"
alltogether_args[7]="$filtex"
alltogether_args[8]="$evt_bkgd_list"
alltogether_args[9]="$se_list"
alltogether_args[10]="$sa_list"

echo ./reduce_alltogether.sh "${alltogether_args[@]}"
"$script_dir"/reduce_alltogether.sh "${alltogether_args[@]}" 

exit

# ## Removing duplicates from the obsID list -- can happen if there are multiple
# ## orbits per obsID
# python -c "from tools import no_duplicates; no_duplicates('$obsID_list')"
# 
# ################################################################################
# ## Now making a filter, gti, event-mode spectrum, Std2 lightcurve and spectrum, 
# ## adding event-mode background spectra, re-binning the total event-mode 
# ## background spectrum, and making a response matrix for ALL obsIDs. 
# ################################################################################
# 
# out_dir="$out_dir_prefix/${prefix}"
# 
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
# 	lastkey='TSTOP DATE-END TIME-END' \
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
# bin_loc=$(python -c "from tools import get_key_val; print get_key_val('$filter_file', 0, 'TIMEPIXR')")
# if (( bin_loc == 0 )); then
# 	maketime infile=$filter_file outfile=$gti_file expr=$filtex name=NAME \
# 		value=VALUE time=Time compact=no clobber=yes prefr=0.0 postfr=1.0
# elif (( bin_loc == 1 )); then
# 	maketime infile=$filter_file outfile=$gti_file expr=$filtex name=NAME \
# 		value=VALUE time=Time compact=no clobber=yes prefr=1.0 postfr=0.0
# else
# 	echo -e"\tWarning: TIMEPIXR is neither 0 nor 1. Setting prefr=postfr=0.5."
# 	echo -e "\tWarning: TIMEPIXR is neither 0 nor 1. Setting prefr=postfr=0.5." >> $progress_log
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
# ################################################################################
# ## Make a mean event-mode spectrum -- needed for pcarsp (in event_mode_bkgd.sh)
# ################################################################################
# 
# echo "Extracting MEAN evt spectrum"
# echo "Extracting MEAN evt spectrum" >> $progress_log
# all_evt="$out_dir/all_evt.pha"
# 
# ## If there are no event files, give error and exit.
# if (( $( wc -l < $se_list ) == 0 )); then
# 
# 	echo -e "\tERROR: No event-mode data files for any obsID. Cannot run seextrct. Exiting."
# 	echo -e "\tERROR: No event-mode data files for any obsID. Cannot run seextrct. Exiting." >> $progress_log
# 	exit
# 	
# ## If there are 100 or more event files, need to add spectra in addpha.py
# elif (( $( wc -l < $se_list ) >= 100 )); then
# 
# 	echo "100 or more event spectra. Adding */event.pha with addpha."
# 	echo "100 or more event spectra. Adding */event.pha with addpha." >> $progress_log
# 	evtpha_list="$out_dir/${prefix}_evtpha.lst"
# 	if [ -e "$evtpha_list" ]; then rm "$evtpha_list"; fi; touch "$evtpha_list"
# 	
# 	for obsid in $( cat $obsID_list ); do
# 		echo "$out_dir/$obsid/event.pha" >> $evtpha_list
# 	done	
# 	
# 	if (( $( wc -l < $evtpha_list ) > 0 )); then
# 		echo python ./addpha.py "$evtpha_list" "$all_evt" "$gti_file"
# 		python "$script_dir"/addpha.py "$evtpha_list" "$all_evt" "$gti_file"
# 	else
# 		echo -e "\tERROR: addpha.py did not run. No event spectra in list."
# 	fi
# 	
# ## If there are 0 < n < 100 event files, combine them in seextrct	
# else
# 
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
# # echo "Extracting MEAN std2 pcu 2 data"
# # echo "Extracting MEAN std2 pcu 2 data" >> $progress_log
# # all_std2="$out_dir/all_std2.pha"
# # cp "$list_dir"/std2_pcu2_cols.lst ./tmp_std2_pcu2_cols.lst
# # 
# # if (( $(wc -l < $sa_list) == 0 )); then
# # 	echo -e "\tERROR: No Standard-2 data files. Cannot run saextrct."
# # 	echo -e "\tERROR: No Standard-2 data files. Cannot run saextrct." >> $progress_log
# # else
# # 	saextrct lcbinarray=10000000 \
# # 		maxmiss=200 \
# # 		infile=@"$sa_list" \
# # 		gtiorfile=- \
# # 		gtiandfile="$gti_file" \
# # 		outroot="${all_std2%.*}" \
# # 		columns=@tmp_std2_pcu2_cols.lst \
# # 		accumulate=ONE \
# # 		timecol="Time" \
# # 		binsz=16 \
# # 		mfracexp=INDEF \
# # 		printmode=BOTH \
# # 		lcmode=RATE \
# # 		spmode=SUM \
# # 		mlcinten=INDEF \
# # 		mspinten=INDEF \
# # 		writesum=- \
# # 		writemean=- \
# # 		timemin=INDEF \
# # 		timemax=INDEF \
# # 		timeint=INDEF \
# # 		chmin=INDEF \
# # 		chmax=INDEF \
# # 		chint=INDEF \
# # 		chbin=INDEF \
# # 		dryrun=no \
# # 		clobber=yes
# # 
# # 	if [ ! -e "${all_std2%.*}.lc" ] ; then
# # 		echo -e "\tERROR: Total Standard-2 light curve not made!"
# # 		echo -e "\tERROR: Total Standard-2 light curve not made!" >> $progress_log
# # 	fi  ## End 'if lightcurve not made', i.e. if saextrct failed
# # 	if [ ! -e "$all_std2" ] ; then
# # 		echo -e "\tERROR: Total Standard-2 spectrum not made!"
# # 		echo -e "\tERROR: Total Standard-2 spectrum not made!" >> $progress_log
# # # 		exit
# # 	fi  ## End 'if spectrum not made', i.e. if saextrct failed
# # fi  ## End 'if there are std2 files in $sa_list'
# # 
# echo "Done with total extractions."
# 
# # ## Deleting the temporary file(s)
# # rm tmp_std2_pcu2_cols.lst
# 
# #######################################################
# ## Adding the extracted event-mode background spectra.
# #######################################################
# 
# echo ./event_mode_bkgd.sh "$out_dir" "$evt_bkgd_list" "$all_evt" "$progress_log"
# "$script_dir"/event_mode_bkgd.sh "$out_dir" "$evt_bkgd_list" "$all_evt" "$progress_log"
# 
# ######################################################
# ## Analyzing filter files to see how many PCUs are on
# ######################################################
# 
# echo ./analyze_filters.sh "$obsID_list" "$prefix"
# "$script_dir"/analyze_filters.sh "$obsID_list" "$prefix"
#

################################################################################
## 					All done!
################################################################################

cd "$current_dir"
echo -e "\nFinished script ‘rxte_reduce_data.sh'" >> $progress_log
echo -e "\nFinished script 'rxte_reduce_data.sh'.\n"

################################################################################
