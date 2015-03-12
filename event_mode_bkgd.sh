#! /bin/bash

################################################################################
##
## Create a background spectrum for all of the event-mode data by summing the
## event-mode background spectra from all the obsIDs in the list, re-binning it
## by energy channel, and making the response matrix for good measure (which
## also creates chan.txt, the file telling how to re-bin the energy channels).
##
## Notes: HEASOFT 6.14 (or higher), bash 3.*, and Python 2.7.* (with supporting
##        libraries) must be installed in order to run this script. 
## 
## Written by Abigail Stevens, A.L.Stevens at uva.nl, 2014-2015 
## 
################################################################################

## Make sure the input arguments are ok
if (( $# != 6 )); then
    echo -e "\t\tUsage: ./event_mode_bkgd.sh <script dir> <list dir> <out dir> \
<evt bkgd list> <total evt spectrum> <progress log>\n"
    exit
fi

eventmodebkgd_args=( "$@" )
script_dir="${eventmodebkgd_args[0]}"
list_dir="${eventmodebkgd_args[1]}"
out_dir="${eventmodebkgd_args[2]}"
evt_bkgd_list="${eventmodebkgd_args[3]}"
all_evt="${eventmodebkgd_args[4]}"
progress_log="${eventmodebkgd_args[5]}"

################################################################################

## If heainit isn't running, start it
if (( $(echo $DYLD_LIBRARY_PATH | grep heasoft | wc -l) < 1 )); then
	. $HEADAS/headas-init.sh
fi

echo "Running event_mode_bkgd.sh"
echo "Running event_mode_bkgd.sh" >> $progress_log

filter_file="$out_dir/all.xfl"
gti_file="$out_dir/all.gti"
ub_bkgd="$out_dir/evt_bkgd_notbinned"

echo "$evt_bkgd_list"

################################################################################
################################################################################

python -c "from tools import time_ordered_list; time_ordered_list('$evt_bkgd_list')" > ./dump.txt
mv ./dump.txt "$evt_bkgd_list"
cd "$out_dir"

###################################################
## Summing the event-mode-style background spectra
###################################################

if (( $( wc -l < "$out_dir/all_event_bkgd.lst" ) > 0 )); then
	echo python ./addpha.py "$out_dir/all_event_bkgd.lst" "$ub_bkgd.pha" "$gti_file"
	python "$script_dir"/addpha.py "$out_dir/all_event_bkgd.lst" "$ub_bkgd.pha" "$gti_file"
else
	echo -e "\tERROR: addpha.py did not run. No event-mode background spectra in list."
fi
if [ ! -e "$ub_bkgd.pha" ]; then
	echo -e "\tERROR: Adding the individual event-mode background spectra did not work."
	echo -e "\tERROR: Adding the individual event-mode background spectra did not work." >> $progress_log
	exit
fi

echo "Background spectrum: $ub_bkgd.pha"

##############################################################################
## Making response matrix -- note that this response matrix assumes only PCU2
##############################################################################

echo "Making a response matrix."
echo "Making a response matrix." >> $progress_log
rsp_matrix="$out_dir/PCU2.rsp"

# if [ -e "$rsp_matrix" ]; then
# 	echo "Response matrix already exists."
# elif [ -e "$all_evt" ]; then
if [ -e "$all_evt" ]; then
	pcarsp -f "$all_evt" -a "$filter_file" -l all -j y -p 2 -m n -n "$rsp_matrix" -z
else
	echo -e "\tERROR: pcarsp was not run. Event-mode spectrum of all obsIDs does not exist."
	echo -e "\tERROR: pcarsp was not run. Event-mode spectrum of all obsIDs does not exist." >> $progress_log
fi

##########################################################################
## Re-binning the background file to have the same energy channels as an 
## event-mode spectrum
##########################################################################

echo "Re-binning the event-mode background spectrum."
echo "Re-binning the event-mode background spectrum." >> $progress_log
rb_bkgd="$out_dir/evt_bkgd_rebinned.pha"

if [ -e "${ub_bkgd}.pha" ] && [ -e "$out_dir/chan.txt" ] ; then
	rbnpha infile="${ub_bkgd}.pha" \
		outfile="$rb_bkgd" \
		binfile="$out_dir/chan.txt" \
		chatter=4 \
		clobber=yes
else
	echo -e "\tERROR: rbnpha was not run. Summed event-mode background spectrum and/or chan.txt do not exist."
	echo -e "\tERROR: rbnpha was not run. Summed event-mode background spectrum and/or chan.txt do not exist." >> $progress_log
fi

################################################################################
## All done!

echo "Finished running event_mode_bkgd.sh."
echo "Finished running event_mode_bkgd.sh." >> $progress_log

################################################################################
