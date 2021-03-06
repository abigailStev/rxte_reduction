#!/bin/bash

################################################################################
##
## Abbie's RXTE data reduction and analysis pipeline
##
## To run, navigate to this directory on the command line, then: ./pipeline.sh
##
## Change the directory names and specifiers before the double '#' row to best
## suit your setup.
## 
## Notes: HEASOFT 6.19.*, bash 3.*, and conda 4.0.7+ with python 2.7.*
## 		  must be installed in order to run this script. Internet
##        access is required for most setups of CALDB.
##
## Author: Abigail Stevens <A.L.Stevens at uva.nl>, 2014-2017
## 
################################################################################

home_dir=$(ls -d ~)  ## Getting the name of the machine's home directory
current_dir=$(pwd)  ## The current directory
script_dir="$home_dir/Dropbox/Research/rxte_reduce"  ## Directory containing the
													 ## data reduction scripts
data_dir="$home_dir/Data/RXTE"  ## Data directory
ps_dir="$home_dir/Dropbox/Research/power_spectra"  ## Directory with power 
												   ## spectrum code
ccf_dir="$home_dir/Dropbox/Research/cross_correlation"  ## Directory with ccf 
														## code
es_dir="$home_dir/Dropbox/Research/energy_spectra"  ## Directory with energy 
													## spectral code
sim_dir="$home_dir/Dropbox/Research/simulate"  ## Directory with QPO simulation 
											   ## code
list_dir="$home_dir/Dropbox/Lists"  ## A folder of lists; tells which files 
									## we're using
out_dir_prefix="$home_dir/Reduced_data"  ## Prefix of output directory
# list_dir="$home_dir/Dropbox/Research/sample_data"
# out_dir_prefix="$home_dir/Dropbox/Research/sample_data"

# prefix="GX339-BQPO"
#prefix="4U1608"
#prefix="XTE1859-BQPO"
#prefix="GX339-4HzCQPO"
prefix="GX339-HFsoft"
#prefix="GRO1655-BQPO"
#prefix="H1743-BQPO"
#prefix="MAXI1659-BQPO"

datamode="E_125us_64M_0_1s"
#datamode="E_1ms_128M_50_8s"
#datamode="SB_250us_0_35_2s"
#datamode="SB_250us_36_249_2s"
#datamode="E_500us_64M_0_1s"
#datamode="E_62us_32M_36_1s"
#datamode="D_1us_0_249_1024_64s_F"

dt=64  ## Multiple of the time resolution of the data for ps and ccf
numsec=64  ## Length of segments in seconds of Fourier segments for analysis

testing=0  ## 1 is yes, 0 is no
# filtering="401:401" ## "no" for QPOs, or "lofreq:hifreq" in Hz for coherent pulsations
filtering="no" ## "no" for QPOs, or "lofreq:hifreq" in Hz for coherent pulsations
#filtering="3:10" ## "no" for QPOs, or "lofreq:hifreq" in Hz for coherent pulsations

day=$(date +%y%m%d)  # make the date a string and assign it to 'day'
# day="150128"
# day="150902"
# day="151119"
# day="151204"

# newfile_list="$list_dir/${prefix}_newfiles_1.lst"
# obsID_list="$list_dir/${prefix}_obsIDs_1.lst"
# event_list="$list_dir/${prefix}_eventlists_1.lst"
# newfile_list="$list_dir/${prefix}_newfiles_2.lst"
# obsID_list="$list_dir/${prefix}_obsIDs_2.lst"
# event_list="$list_dir/${prefix}_eventlists_2.lst"
# obsID_list="$list_dir/${prefix}_obsIDs_half.lst"
# event_list="$list_dir/${prefix}_eventlists_half.lst"
# newfile_list="$list_dir/${prefix}_newfiles.lst"
obsID_list="$list_dir/${prefix}_obsIDs.lst"

# newfile_list="$list_dir/${prefix}_${datamode}_1.xdf"
# obsID_list="$list_dir/${prefix}_obsIDs_1.lst"
# event_list="$list_dir/${prefix}_eventlists_1.lst"
# newfile_list="$list_dir/${prefix}_${datamode}_2.xdf"
# obsID_list="$list_dir/${prefix}_obsIDs_2.lst"
# event_list="$list_dir/${prefix}_eventlists_2.lst"
# newfile_list="$list_dir/${prefix}_${datamode}_half.xdf"
# obsID_list="$list_dir/${prefix}_obsIDs_half.lst"
# event_list="$list_dir/${prefix}_eventlists_half.lst"
newfile_list="$list_dir/${prefix}_${datamode}.xdf"
# obsID_list="$list_dir/${prefix}_obsIDs_goodSN.lst"
# event_list="$list_dir/${prefix}_eventlists_goodSN.lst"
# event_list="$list_dir/${prefix}_eventlists_9.lst"
event_list="$list_dir/${prefix}_eventlists.lst"

################################################################################
################################################################################

## Make sure there aren't any input arguments
if (( $# != 0 )); then
    echo -e "\tERROR: Do not give command line arguments. Usage: ./pipeline.sh\n"
    exit
fi

## If heainit isn't running, start it
if (( $(echo $DYLD_LIBRARY_PATH | grep heasoft | wc -l) < 1 )); then
	. $HEADAS/headas-init.sh
fi

################################################################################
##
##		Download the data
##
################################################################################
echo -e "\n--- Download data ---"

#echo ./download_obsIDs.sh "$obsID_list"
#"$script_dir"/download_obsIDs.sh "$obsID_list"


################################################################################
##																			  ##
## 		Make list of new files to be reduced/analyzed						  ##
##																			  ##
################################################################################
echo -e "\n--- Make list of files to be reduced ---"

#echo time ./xtescan.sh "${prefix}" "$obsID_list"
#time "$script_dir"/xtescan.sh "${prefix}" "$obsID_list"


################################################################################
##																			  ##
## 		Reduce RXTE data													  ##
##																			  ##
################################################################################
echo -e "\n--- Reduce data ---"
cd "$script_dir"

echo "$(pwd)/run.log"
echo "$(pwd)/progress.log"
## The first line is good for debugging with only one obsID
## The second line is for long runs. 
time "$script_dir"/rxte_reduce_data.sh "$newfile_list" "$obsID_list" "${prefix}"
#echo time ./rxte_reduce_data.sh "$newfile_list" "$obsID_list" "${prefix}" > run.log
#time "$script_dir"/rxte_reduce_data.sh "$newfile_list" "$obsID_list" "${prefix}" > run.log


################################################################################
##																			  ##
## 		Plot the Standard-2 light curve										  ##
##																			  ##
################################################################################
echo -e "\n--- Plot Standard 2 light curve ---"
cd "$script_dir"

#lc_plot="$out_dir_prefix/${prefix}/std2_lc.png"
#echo python ./plot_std2_lightcurve.py "$prefix" "$out_dir_prefix/${prefix}/all_std2.lc" "$lc_plot"
#python "$script_dir"/plot_std2_lightcurve.py "$prefix" "$out_dir_prefix/${prefix}/all_std2.lc" "$lc_plot"
#if [ -e "$lightcurve_plot" ]; then open "$lightcurve_plot"; fi


################################################################################
##																			  ##
## 		Make lists of good events											  ##
##																			  ##
################################################################################
echo -e "\n--- Good event list ---"
cd "$script_dir"

echo time ./good_events.sh "$prefix" "$obsID_list" "$event_list"
time "$script_dir"/good_events.sh "$prefix" "$obsID_list" "$event_list"


################################################################################
##																			  ##
## 		Power spectrum 														  ##
##																			  ##
################################################################################
echo -e "\n--- Power spectrum ---"
cd "$ps_dir"

# time "$ps_dir"/loop_powerspec.sh
#
## TODO: NEED TO UPDATE with run_powerspec.sh

################################################################################
##																			  ##
## 		Cross-correlation function											  ##
##																			  ##
################################################################################
echo -e "\n--- CCF ---"
cd "$ccf_dir"

# time "$ccf_dir"/loop_ccf.sh
# 
## TODO: NEED TO UPDATE, with run_ccf.sh
#


################################################################################
##																			  ##
## 		Energy spectra														  ##
##																			  ##
################################################################################
echo -e "\n--- Energy spectra ---"
cd "$es_dir"

# echo time ./run_energyspec.sh "$prefix" "$dt" "$numsec" "$testing" "$day"
# time "$es_dir"/run_energyspec.sh "$prefix" "$dt" "$numsec" "$testing" "$day"

#echo time "$es_dir"/phasespec_fitting.sh "$prefix" "$dt" "$numsec" "$testing" \
#        "$day"
#source "$es_dir"/phasespec_fitting.sh "$prefix" "$dt" "$numsec" "$testing" \
#        "$day"


################################################################################
##																			  ##
##		Simulate energy spectra and lags
##																			  ##
################################################################################
echo -e "\n--- Simulate energy spectra and lags ---"
cd "$sim_dir"

#echo time ./run_fake_qpo_spectra.sh "$prefix" "$dt" "$numsec" "$testing" "$day"
#time "$sim_dir"/run_fake_qpo_spectra.sh "$prefix" "$dt" "$numsec" "$testing" \
# 		"$day"


################################################################################
## All done!
echo -e "\nFinished pipeline.sh."
cd "$current_dir"
echo " "
tput bel
################################################################################
