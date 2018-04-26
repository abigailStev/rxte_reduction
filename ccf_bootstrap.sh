#!/bin/bash

################################################################################
##
## Bootstrapping errors on CCF for testing spectral fits. This is basically the
## second half of pipeline.sh but for bootstrapping.
##
## Change the directory names and specifiers before the double '#' row to best
## suit your setup. Also need to check these within run_bootstrap_ccf.sh, 
## sed_fit_bootstrap.sh, and simulate_qpo_bootstrap.sh.
## 
## Notes: HEASOFT 6.19.*, bash 3.*, and conda 4.0.7+ with python 2.7.*
## 		  must be installed in order to run this script.  Internet
##        access is required for most setups of CALDB.
##
## Written by Abigail Stevens <A.L.Stevens at uva.nl>, 2015-2016
## 
################################################################################

home_dir=$(ls -d ~)  ## Getting the name of the machine's home directory
current_dir=$(pwd)  ## The current directory

ccf_dir="$home_dir/Dropbox/Research/cross_correlation"  ## Directory with ccf 
														## code
es_dir="$home_dir/Dropbox/Research/energy_spectra"  ## Directory with energy 
													## spectrum code
sim_dir="$home_dir/Dropbox/Research/simulate"  ## Directory with simulation code													
list_dir="$home_dir/Dropbox/Lists"  ## A folder of lists; tells which files 
									## we're using
prefix="GX339-BQPO"

dt=64  ## Multiple of the time resolution of the data for ps and ccf
numsec=64  ## Length of segments in seconds of Fourier segments for analysis

#boot_num=10
boot_num=5537  ## Number of bootstrap realizations to do; 1 to boot_num, incl.
testing=0  ## 1 is yes, 0 is no
filtering="no"  ## "no" for QPOs, or "lofreq:hifreq" in Hz for coherent pulsations

# day=$(date +%y%m%d)  ## make the date a string and assign it to 'day'
day="151204"

newfile_list="$list_dir/${prefix}_${datamode}.xdf"
event_list="$list_dir/${prefix}_eventlists_9.lst"

################################################################################
################################################################################

## Make sure there aren't any input arguments
if (( $# != 0 )); then
    echo -e "\tERROR: Do not give command line arguments. "\
    		"Usage: ./ccf_bootstrap.sh\n"
    exit
fi

## If heainit isn't running, start it
if (( $(echo $DYLD_LIBRARY_PATH | grep heasoft | wc -l) < 1 )); then
	. $HEADAS/headas-init.sh
fi

################################################################################
##																			  ##
## 		Cross-correlation function											  ##
##																			  ##
################################################################################
echo -e "\n--- CCF ---"
cd "$ccf_dir"

# time "$ccf_dir"/run_bootstrap_ccf.sh "$event_list" "$prefix" "$dt" \
# 		"$numsec" "$testing" "$day" "$filtering" "$boot_num"

################################################################################
##																			  ##
## 		Energy spectra														  ##
##																			  ##
################################################################################
echo -e "\n--- Energy spectra ---"
cd "$es_dir"

#source "$es_dir"/bootstrap_phasespec_fit.sh "$prefix" "$dt" "$numsec" \
#       "$testing" "$day" "$boot_num"

################################################################################
##																			  ##
## 		Simulating lag-energy spectra										  ##
##																			  ##
################################################################################
echo -e "\n--- Simulating lag-energy spectra ---"
cd "$sim_dir"

 time python "$sim_dir"/sim_qpo_bootstrap.py \
 		--prefix "$prefix" \
 		--dt_mult "$dt" \
 		--nsec "$numsec" \
 		--testing "$testing" \
 		--day "$day" \
 		--boot "$boot_num"

################################################################################
## All done!
echo -e "\nFinished ccf_bootstrap.sh."
cd "$current_dir"
echo " "
################################################################################
