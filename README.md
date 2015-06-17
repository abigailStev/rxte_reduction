# rxte_reduction repository

All of this is designed for RXTE PCA event-mode data. Heasoft must be installed
and CALDB must be in working order.

## Contents

### addpha.py
Adds together the values in two or more .pha (i.e., energy spectrum) files.

### analyze_filters.sh
Analyzes many filter files to determine how many PCUs were on for how long, 
and other fun things.

### apply_gti.py
Applies a GTI (good times interval) to an event list. 

### channel_to_energy.py 
Converts e-c_table.txt into a list of keV energy boundaries of each detector 
mode channel. Used for cross_correlation/plot_2d.py, for example.

### data_dl.sh


### download_obsIDs.sh


### e-c_table.txt
Table for energy-to-channel conversions for RXTE epochs. Downloaded from 
HEASARC.

### event_mode_bkgd.sh
Called within rxte_reduce_data.sh. Creates a background spectrum for all the 
event-mode data and re-bins it so that the energy channels match. Also creates
the response matrix.

### good_event.sh
Decodes the binary event list and runs apply_gti.py on it. Copies filenames to 
lists.

### gti_and_bkgd.sh


### indiv_extract.sh


### LICENSE.md
The code in this repository is licensed under the MIT License. Details are in 
this document.

### pcu_filter.py


### pipeline.sh


### plot_std2_lightcurve.py
Plots a Standard-2 lightcurve, to show general trends of the data.

### README.md
This document.

### reduce_alltogether.sh


### rxte_reduce_data.sh
This does it all! Often times, chunks are commented out since I don't want to do
it all. Makes a list of obsIDs, creates filter files, creates GTIs, copies 
relevant raw data products to the correct new directory with sensible names, 
makes background spectra for standard-2 and event data modes, extracts 
standard-2 spectra and lightcurve and event-mode spectra and light curve. Does
the above for each obsID, and for everything all together.

### xtescan.sh
