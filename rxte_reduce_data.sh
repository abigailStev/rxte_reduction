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
## WARNING: This script deletes files using a wildcard '*' just after the double 
## '#' row. Check to be sure it's ok they're erased! Uncomment the 'ls' 
## statements and comment the 'rm' statements to check what will be deleted.
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
    echo -e "\t\tUsage: ./rxte_reduce_data.sh <newfiles.xdf> <obsIDs.lst> \
<prefix>\n"
    exit
fi

rxtereduce_args=( "$@" )

newfilelist="${rxtereduce_args[0]}"  ## File with list of new files; with 
                                     ## extension xdf, from xtescan or
									 ## interactive xdf
obsID_list="${rxtereduce_args[1]}"  ## File with list of obsIDs, to be written 
									## to
prefix="${rxtereduce_args[2]}"  ## Prefix of directories and files (either 
								## proposal ID or object nickname)
		   
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

################################################################################

progress_log="$current_dir/progress.log"  ## File with concise description of 
										  ## this script's progress
filter_list="${out_dir_prefix}/${prefix}/all_filters.lst"  ## This gets changed later on
evt_bkgd_list="${out_dir_prefix}/${prefix}/all_event_bkgd.lst"
se_list="${out_dir_prefix}/${prefix}/all_evt.lst"
sa_list="${out_dir_prefix}/${prefix}/all_std2.lst"

std2pcu2_cols="$list_dir/std2_pcu2_cols.lst"
bitfile="$list_dir/bitfile_evt_PCU2" ## Using bitfile_evt_PCU2 for only PCU2 photons

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

echo "Current directory: $current_dir"
echo "Data directory: $data_dir"
echo "List of new files in desired data mode: $newfilelist"
echo "ObsID list: $obsID_list"

if [ -d "${out_dir_prefix}/${prefix}" ]; then
# 	ls "${out_dir_prefix}/${prefix}"/*/evt_*.pca
# 	ls "${out_dir_prefix}/${prefix}"/*/std2_*.pca
	rm "${out_dir_prefix}/${prefix}"/*/evt_*.pca
	rm "${out_dir_prefix}/${prefix}"/*/std2_*.pca
fi

if [ ! -d "${out_dir_prefix}/${prefix}" ]; then mkdir -p "${out_dir_prefix}/${prefix}"; fi
if [ -e "$filter_list" ]; then rm "$filter_list"; fi; touch "$filter_list"
if [ -e "$evt_bkgd_list" ]; then rm "$evt_bkgd_list"; fi; touch "$evt_bkgd_list"
if [ -e "$se_list" ]; then rm "$se_list"; fi; touch "$se_list"
if [ -e "$sa_list" ]; then rm "$sa_list"; fi; touch "$sa_list"
## Re-writing over the obsID list in case not every obsID downloaded has the 
## data mode we're interested in.
if [ -e "$obsID_list" ]; then rm "$obsID_list"; fi; touch "$obsID_list"

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
	
	obs_dir=$( dirname `dirname ${newfile}` )  ## Where the downloaded 
											   ## observation is stored
	echo "Observation data directory: $obs_dir"
	
	IFS='/' read -a directories <<< "$newfile"
	obsID="${directories[6]}"
	echo "obsID: $obsID"
	echo "$obsID" >> $obsID_list
	echo "Starting run for obsID=$obsID" >> $progress_log

	out_dir="${out_dir_prefix}/${prefix}/$obsID"  ## Where you want your output 
											  	  ## to go for each observation 
											  	  ## (filter files, reduced data 
											  	  ## products)
	echo "Output directory: $out_dir"
	
	## If the output directory doesn't already exist, make it
	if [ ! -d "$out_dir" ]; then mkdir -p "$out_dir"; fi
	
	filter_file="$out_dir/filter.xfl"
	gti_file="$out_dir/gti_file.gti"

	########################
	## Making a filter file
	########################
	
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
	
	###################################################
	## Herding the std2 files into the right directory
	###################################################
	
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
		new_std2="$out_dir/std2_${m}".pca
		
		if [ ${std2file##*.} == gz ]; then  ## If it's gzipped
			cp $std2file "$new_std2".gz
			gunzip -f "$new_std2".gz
		else  ## if it doesn't end in gz
			cp $std2file "$new_std2"
		fi
			
		if [ -e "$new_std2" ]; then
			echo "$new_std2" >> $sa_list
		fi
		
		(( m++ ))
		
	done  ## End for-loop through each Std2 file
	
	#########################################################
	## Herding the event mode files into the right directory
	## Get the data mode from newfile in newfilelist 
	## (made in xtescan or interactive xdf)
	#########################################################

	mode_file=$( echo `basename $newfile` ) 
	eventfile="$obs_dir"/pca/"${mode_file}"
	echo "eventfile = $eventfile"
	
	m=1
	while [ -e "$out_dir/evt_${m}".pca ]; do
		(( m++ ))
	done
	new_evt="$out_dir/evt_${m}".pca
# 	echo "$new_evt"

	if [ ${eventfile##*.} == gz ]; then  ## If it's gzipped
		cp $eventfile "$new_evt".gz
		gunzip -f "$new_evt".gz
	else  ## if it doesn't end in gz
		cp $eventfile "$new_evt"
	fi
		
	if [ -e "$new_evt" ]; then
		echo "$new_evt" >> $se_list
	fi
	
	#############################################
	## Now making the GTI and background files.
	#############################################
		
	gtibkgd_args=()
	gtibkgd_args[0]="$list_dir"
	gtibkgd_args[1]="$script_dir"
	gtibkgd_args[2]="$out_dir"
	gtibkgd_args[3]="$progress_log"
	gtibkgd_args[4]="$gti_file"
	gtibkgd_args[5]="$filter_file"
	gtibkgd_args[6]="$filtex"
	gtibkgd_args[7]="$bkgd_model"
	gtibkgd_args[8]="$saa_history"
	gtibkgd_args[9]="$std2pcu2_cols"
	gtibkgd_args[10]="$evt_bkgd_list"

	echo ./gti_and_bkgd.sh "${gtibkgd_args[@]}"
	"$script_dir"/gti_and_bkgd.sh "${gtibkgd_args[@]}"
	
	##########################################################
	## Built-in extraction of Standard-2f and event-mode data
	##########################################################
	
	indivextract_args=()
	indivextract_args[0]="$list_dir"
	indivextract_args[1]="$out_dir"
	indivextract_args[2]="$progress_log"
	indivextract_args[3]="$gti_file"
	indivextract_args[4]="$std2pcu2_cols"
	indivextract_args[5]="$bitfile"
	
 	echo ./indiv_extract.sh "${indivextract_args[@]}"
	"$script_dir"/indiv_extract.sh "${indivextract_args[@]}"

	echo -e "Finished run for obsID=$obsID \n"				
	echo -e "Finished run for obsID=$obsID \n" >> $progress_log
	(( current_file_num++ ))
	
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
alltogether_args[11]="$std2pcu2_cols"
alltogether_args[12]="$bitfile"

echo ./reduce_alltogether.sh "${alltogether_args[@]}"
"$script_dir"/reduce_alltogether.sh "${alltogether_args[@]}" 


################################################################################
## 					All done!
################################################################################

cd "$current_dir"
echo -e "\nFinished script ‘rxte_reduce_data.sh'" >> $progress_log
echo -e "\nFinished script 'rxte_reduce_data.sh'.\n"

################################################################################
