#!//anaconda/bin/python
import argparse
from astropy.io import fits
import numpy as np
from datetime import datetime
import os
import subprocess
import tools

__author__ = "Abigail Stevens"
__author_email__ = "A.L.Stevens at uva.nl"
__year__ = "2015"
__description__ = "Adds multiple pha spectra together. Sums the exposure time \
and counts. Error is summed in quadrature."

"""
		addpha.py

Written in Python 2.7.

Example call: python addpha.py tmp_phas.txt ./tmp_out.pha tmp_all.gti
	where tmp_phas.txt has a list of the pha files to be added
		  tmp_out.pha is the name of the output spectrum
		  tmp_all.gti is the gti used on the individual pha files

"""

################################################################################
if __name__ == "__main__":
	
	###############################
	## Parsing the input arguments
	###############################
	
    parser = argparse.ArgumentParser(usage='addpha.py file_list outfile.pha \
gti_file.gti', description='Adds together multiple pha spectra. Sums the \
exposure time and counts, error is summed in quadrature.', epilog='All \
arguments are required.')
    	
    parser.add_argument('file_list', help="The full path of the (ASCII/txt/\
dat) input file listing the spectra to be summed. One file per line.")
        
    parser.add_argument('out_file', help="The full path of the (.pha) \
output file to write the summed spectra and exposure time to.")
    
    parser.add_argument('gti_file', help="The GTI file for all files being \
added.")

    args = parser.parse_args()
    
    #####################
    ## Setting things up
    #####################
    
    if not os.path.isfile(args.file_list):
    	raise Exception("ERROR: File list does not exist.")
    	
    ## Make list of file names from the list
    infiles = [line.strip() for line in open(args.file_list)]
    
    ## Finding the first fits file that exists
    i=0
    try:
		while not os.path.isfile(infiles[i]): 
			i += 1
    except IndexError:
		print "\tERROR: No input .pha files exist in %s. Exiting." % args.file_list
		exit()
    	
#     print " i = ", i
    
    ## Need to copy the first file and write over it -- this way it has all the
    ## header information needed by other FTOOLS. Relevant keywords are also 
    ## overwritten below.
    subprocess.call(["cp", infiles[i], args.out_file])
    
    ## Get number of detector energy channels
    detchans = tools.get_key_val(infiles[i], 1, "DETCHANS")  
    
    ##########################
    ## Initializing variables
    ##########################
    
    exposure = 0.0
    spectrum = np.zeros(detchans)
    sq_error = np.zeros(detchans)
    channels = np.arange(detchans)
    tstop = 0
    dateend = " "
    timeend = " "
    tstopi = 0
    tstopf = 0
    
    ###########################################################################
    ## Looping through the spectra to sum the exposure time, counts, and error
    ###########################################################################
    
    for fits_file in infiles:
    	try:
    		file_hdu = fits.open(fits_file)
    	except IOError:
			print "\tERROR: File does not exist: %s" % fits_file
			continue
    	
    	exposure += float(file_hdu[1].header['EXPOSURE'])
    	spectrum += file_hdu[1].data.field('COUNTS')
    	sq_error += np.square(file_hdu[1].data.field('STAT_ERR'))
    	
    	if float(file_hdu[0].header['TSTOP']) > tstop:
			tstop = float(file_hdu[0].header['TSTOP'])
			dateend = file_hdu[0].header['DATE-END']
			timeend = file_hdu[0].header['TIME-END']
			tstopi = file_hdu[2].header['TSTOPI']
			tstopf = file_hdu[2].header['TSTOPF']
    	
    	file_hdu.close()
		
	## Done looping through fits files
	
    error = np.sqrt(sq_error)  ## because adding in quadrature
	
	##########################################
	## Getting the GTI data from the gti file 
	## (to save to ext 2 of the output)
	##########################################
	
    try:
    	gti_hdu = fits.open(args.gti_file)
    except IOError:
    	print "\tERROR: File does not exist: %s" % args.gti_file
    	exit()
    	
    all_gti_data = gti_hdu[1].data
    gti_hdu.close()
	
	#########################################
    ## Making FITS output (header and table)
    #########################################
    
    out_hdu = fits.open(args.out_file, mode='update')
	
	## Saving extension 1 table data
    tbdata = out_hdu[1].data
    tbdata['COUNTS'] = spectrum
    tbdata['STAT_ERR'] = error
    
    ## Saving extension 2 table data
    gtidata = out_hdu[2].data
    gtidata = all_gti_data
	
	## Updating header values for all three extensions
    hdr0 = out_hdu[0].header
    hdr0.set('TSTOP', tstop)
    hdr0.set('DATE-END', dateend)
    hdr0.set('TIME-END', timeend)
    hdr0.set('CREATOR', "addpha.py")
    hdr1 = out_hdu[1].header
    hdr1.set('TSTOP', tstop)
    hdr1.set('DATE-END', dateend)
    hdr1.set('TIME-END', timeend)
    hdr1.set('EXPOSURE', exposure)
    hdr1.set('FILEN1', args.file_list)
    hdr1.set('CREATOR', "addpha.py")
    hdr2 = out_hdu[2].header
    hdr2.set('TSTOPI', tstopi)
    hdr2.set('TSTOPF', tstopf)
    hdr2.set('DATE-END', dateend)
    hdr2.set('TIME-END', timeend)
    hdr2.set('ONTIME', exposure)
    hdr2.set('CREATOR', "addpha.py")
	
	## Saving the changes
    out_hdu.flush()
    out_hdu.close()

## End of program 'addpha.py'

################################################################################
