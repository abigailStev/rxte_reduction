import argparse
from astropy.io import fits
import numpy as np
from datetime import datetime
import os

__author__ = "Abigail Stevens"
__author_email__ = "A.L.Stevens@uva.nl"
__year__ = "2015"
__description__ = "Adds multiple pha spectra together. Sums the exposure time \
and counts. Error is summed in quadrature."

"""
		addpha.py

Written in Python 2.7.

Example: python addpha.py tmp_phas.txt tmp_out.pha

"""

################################################################################
if __name__ == "__main__":
	
	###############################
	## Getting the input arguments
	###############################
	
    parser = argparse.ArgumentParser(usage='addpha.py file_list outfile.pha', \
description='Adds together multiple pha spectra. Sums the exposure time and \
counts, error is summed in quadrature.', epilog='')
    	
    parser.add_argument('file_list', help="The full path of the (ASCII/txt/\
dat) input file listing the spectra to be summed. One file per line.")
        
    parser.add_argument('out_file', help="The full path of the (.pha) \
output file to write the summed spectra and exposure time to.")
        
    args = parser.parse_args()
    
    ##########################
    ## Initializing variables
    ##########################
    
    infiles = [line.strip() for line in open(args.file_list)]
    
    exposure = 0.0
    spectrum = np.zeros(256)
    sq_error = np.zeros(256)
    channels = np.arange(256)
    
    ###########################################################################
    ## Looping through the spectra to sum the exposure time, counts, and error
    ###########################################################################
    
    for fits_file in infiles:
    	file_hdu = fits.open(fits_file)		
    	exposure += float(file_hdu[1].header['EXPOSURE'])
    	spectrum += file_hdu[1].data.field('COUNTS')
    	sq_error += np.square(file_hdu[1].data.field('STAT_ERR'))
    	file_hdu.close()
		
	## Done looping through fits files
	
    error = np.sqrt(sq_error)  ## because adding in quadrature
    
    #########################################
    ## Making FITS output (header and table)
    #########################################
    
    ## Making FITS header (extension 0)
    prihdr = fits.Header()
    prihdr.set('TYPE', "Summed energy spectra.")
    prihdr.set('DATE', str(datetime.now()), "YYYY-MM-DD localtime")
    prihdr.set('FILELIST', args.file_list)
    prihdr.set('EXPOSURE', exposure, "seconds")
    prihdu = fits.PrimaryHDU(header=prihdr)
    
    ## Making FITS table (extension 1)
    col1 = fits.Column(name='CHANNEL', format='I', array=channels)
    col2 = fits.Column(name='COUNTS', unit='count', format='D', \
    	array=spectrum)
    col3 = fits.Column(name='STAT_ERR', unit='count', format='D', \
    	array=error)
    cols = fits.ColDefs([col1, col2, col3])
    tbhdu = fits.BinTableHDU.from_columns(cols)
    
    ## If the file already exists, remove it
    if os.path.isfile(args.out_file):
    	os.remove(args.out_file)
    
    ## Writing to a FITS file
    thdulist = fits.HDUList([prihdu, tbhdu])
    thdulist.writeto(args.out_file)	

## End of program 'addpha.py'

################################################################################
