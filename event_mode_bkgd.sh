#! /bin/bash

###############################################################################
##
## Create a background spectrum for all of the event-mode data by summing the
## event-mode background spectra from all the obsIDs in the list, re-binning it
## by energy channel, and making the response matrix for good measure (which
## also creates chan.txt, the file telling how to re-bin the energy channels).
## 
## Abigail Stevens, A.L.Stevens@uva.nl, 2014-2015 
## 
###############################################################################

## Make sure the input arguments are ok
if (( $# != 4 )); then
    echo -e "\t\tUsage: ./event_mode_bkgd.sh <output dir> <evt bkgd list> <total evt spectrum> <progress log>"
    exit
fi

out_dir=$1
bkgd_list=$2
all_evt=$3
progress_log=$4

## If heainit isn't running, start it
if (( $(echo $DYLD_LIBRARY_PATH | grep heasoft | wc -l) < 1 )); then
	. $HEADAS/headas-init.sh
fi

echo "Running event_mode_bkgd.sh"
echo "Running event_mode_bkgd.sh" >> $progress_log

home_dir=$(ls -d ~)  # the -d flag is extremely important here
list_dir="$home_dir/Dropbox/Lists"
filter_file="$out_dir/all.xfl"
cp "$bkgd_list" "$out_dir/all_event_bkgd.lst"

ub_bkgd="$out_dir/evt_bkgd_notbinned"

cd "$out_dir"

#############################################################################
## This is a work-around. Should probably write my own script so that I can
## add up more than 35 pha files!! Generally, need to do this part by hand.
#############################################################################

## If there's only one event file, don't need to add bkgd spectra. 
## If not, add them.
if (( $(wc -l < $bkgd_list) == 1 )) ; then

	only_evt_bkgd_pha=$(cat $bkgd_list)
	echo "$only_evt_bkgd_pha"
	cp "$only_evt_bkgd_pha" "$ub_bkgd.pha"
	
else
	asdir="./tmp_addspec"; mkdir "$asdir"; cd "$asdir"
	as_sums="addspec_listofsums.lst"
	if [ -e "$as_sums" ]; then rm "$as_sums"; fi; touch "$as_sums"
	i=1; j=1
	as_list="addspec_list_${i}.lst"
	if [ -e "$as_list" ]; then rm "$as_list"; fi; touch "$as_list"
	
	## addspec only allows to sum ~35 files at ones. So I break the files 
	## into groups of 30, sum them, and then at the end I sum each of those
	## sub-sums to get my total background spectrum.
	
	for item in $(cat "$bkgd_list"); do
		cp $item "./${j}_"$(basename $item)
# 		echo "${j}_$(basename $item)"
		echo "${j}_$(basename $item)" >> "$as_list"
		
		if (( j % 30 == 0 )) ; then 
# 			echo -e "\ti = $i"
			temp_evt_bkgd="temp_evt_bkgd_${i}"
			if [ -e "$temp_evt_bkgd.pha" ]; then rm "$temp_evt_bkgd.pha"; fi
# 			open "$as_list"

			addspec infil="$as_list" \
				outfil="$temp_evt_bkgd" \
				qaddrmf=no \
				qsubback=no \
				clobber=no
			echo "$temp_evt_bkgd.pha" >> $as_sums
			(( i+=1 ))
			as_list="addspec_list_${i}.lst"
			if [ -e "$as_list" ]; then rm "$as_list"; fi; touch "$as_list"
		fi
		(( j+=1 ))

	done
	
	## Doing the last leg (since it doesn't get done otherwise)
	if (( j % 10 != 0 )); then
		temp_evt_bkgd="temp_evt_bkgd_${i}"
		if [ -e "$temp_evt_bkgd.pha" ]; then rm "$temp_evt_bkgd.pha"; fi

		addspec infil="$as_list" \
			outfil="$temp_evt_bkgd" \
			qaddrmf=no \
			qsubback=no \
			clobber=no
		echo "$temp_evt_bkgd.pha" >> $as_sums
	fi
	
	################################################
	## Now summing the sum groups of bkgd pha files
	################################################

	temp_evt_bkgd="temp_evt_bkgd_total"
	if [ -e "$temp_evt_bkgd.pha" ]; then rm "$temp_evt_bkgd.pha"; fi
	
	addspec infil="$as_sums" \
		outfil="$temp_evt_bkgd" \
		qaddrmf=no \
		qsubback=no \
		clobber=no

	if [ -e "$temp_evt_bkgd.pha" ]; then
		mv "$temp_evt_bkgd.pha" "$ub_bkgd.pha"
	else
		echo -e "\tERROR: addspec of sums failed."
		echo -e "\tERROR: addspec of sums failed." >> $progress_log
	fi
	
	cd "$out_dir"
	rm -rf "$asdir"  ## Removing the temporary directory
fi

if [ ! -e "$ub_bkgd.pha" ]; then
	echo -e "\tERROR: Adding the individual event-mode background spectra did not work."
	echo -e "\tERROR: Adding the individual event-mode background spectra did not work." >> $progress_log
fi

echo "Background spectrum: $ub_bkgd.pha"

###########################
## Making response matrix
###########################

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

###############################################################################
## All done!

## Deleting temporary file(s)
rm "$bkgd_list"

echo "Finished running event_mode_bkgd.sh."
echo "Finished running event_mode_bkgd.sh." >> $progress_log

###############################################################################
