# rxte_reduction repository

All of this is designed for RXTE PCA event-mode data. HEASOFT must be installed
and CALDB must be in working order. 

This code downloads RXTE data from a list of obsIDs, scans it to see what types
of data are available, filters it, and makes it into a nice astropy table FITS 
event list, to be read by spectral-timing code.


## Contents

### addpha.py
Adds together the values in two or more .pha (i.e., energy spectrum) files. Used
in reduce_alltogether.sh.

### analyze_filters.sh
Analyzes many filter files to determine how many PCUs were on for how long, 
and other fun things. Used in reduce_alltogether.sh.

### apply_gti.py
Applies a GTI (good times interval) to an event list and saves the filtered 
event list as an astropy table to a FITS file. Used in good_event.sh.

### channel_to_energy.py 
Converts e-c_table.txt into a list of keV energy boundaries of each detector 
mode channel. Used for cross_correlation/plot_2d.py, for example.

### download_obsIDs.sh
Downloads RXTE data given a list of observation IDs with extension ".lst". Used
in pipeline.sh.

### e-c_table.txt
Table for energy-to-channel conversions for RXTE epochs. Downloaded from 
HEASARC.

### event_mode_bkgd.sh
Called within rxte_reduce_data.sh. Creates a background spectrum for all the 
event-mode data and re-bins it so that the energy channels match. Also creates
the response matrix.

### good_event.sh
Decodes the binary event list and runs apply_gti.py on it. Copies filenames to 
lists. Used in pipeline.sh.

### gti_and_bkgd.sh
Runs maketime to create a GTI file from a filter file, pcabackest to estimate 
the background of the RXTE PCA, and saextrct to extract the background spectrum.
Used in rxte_reduce_data.sh.

### indiv_extract.sh
Extracts light curves and spectra for individual observations, for Standard-2, 
Standard-1, and event-mode data. Used in rxte_reduce_data.sh.

### LICENSE.md
The code in this repository is licensed under the MIT License. Details are in 
this document.

### pcu_filter.py
Looks at and plots which PCUs are on at what times during an observation 
(given a filter file). Used in analyze_filters.sh.

### pipeline.sh
This is my master script. It runs: download_obsIDs.sh, xtescan.sh, 
rxte_reduce_data.sh, plot_std2_lightcurve.py, and good_events.sh. Currently
does not run power spectral code, cross spectral code, and energy spectral 
fitting code.

### plot_std2_lightcurve.py
Plots a Standard-2 light curve (16s binning) to show general trends of the data.
Used in pipeline.sh.

### README.md
This document.

### reduce_alltogether.sh
This reduces multiple RXTE obsIDs all together (as the name implies). Merges 
filter files, makes GTI from merged filter files, extracts a mean event-mode 
spectrum, makes a mean Standard-2 spectrum and lightcurve, runs 
event_mode_bkgd.sh and analyze_filters.sh. Open it up and be sure that some of
these things aren't commented out if you want to use them.

### rxte_reduce_data.sh
Reduces RXTE raw data. Often times, chunks are commented out since I don't want 
to do it all. Makes a list of obsIDs, creates filter files, creates GTIs, copies 
relevant raw data products to the correct new directory with sensible names, 
makes background spectra for Standard-2 and event data modes, extracts 
Standard-2 spectra and lightcurve and event-mode spectra and light curve. Does
the above for each obsID, and for everything all together. Used in pipeline.sh.
Uses many of the smaller scripts in this directory.

### xtescan.sh
Determines the data mode and configuration/parameters/settings of each obsID in
the downloaded data. Used in pipeline.sh.


## Authors and License
* Abigail Stevens (UvA API)

Pull requests are welcome!

All code is Copyright 2013-2016 The Authors, and is distributed under the MIT 
Licence. See LICENSE for details. If you are interested in the further 
development of rxte_reduction, please [get in touch via the issues]
(https://github.com/abigailstev/rxte_reduction/issues)!


[![astropy](http://img.shields.io/badge/powered%20by-AstroPy-orange.svg?style=flat)](http://www.astropy.org/) 
