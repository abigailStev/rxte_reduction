#!//anaconda/bin/python
import argparse
import numpy as np
from astropy.io import fits
import itertools
import os
from tools import get_key_val   # https://github.com/abigailStev/whizzy_scripts

__author__ = "Abigail Stevens"
__author_email__ = "A.L.Stevens@uva.nl"
__year__ = "2014-2015"
__description__ = "Applies a GTI to an RXTE decoded event list, to filter out \
events in bad times. This code assumes that the GTI times have not been \
previously corrected with TIMEZERO, but does assume the start time is at the \
front of a time bin and the end time is at the end of a time bin."

"""
		apply_gti.py

Written in Python 2.7.

"""

################################################################################
def dat_out(out_file, gti_file, event_list, good_time, good_chan, good_pcu):
	"""
			dat_out
	
	Writes good events to a dat output file.
	
	"""
	
	print "Output file:", out_file

	out = open(out_file, 'w')
	out.write("# \tCreated in apply_gti.py")
	out.write("\n# Decoded event list: %s" % event_list)
	out.write("\n# GTI applied: %s" % gti_file)
	out.write("\n# ")
	out.write("\n# Column 1: TIME (corrected with TIMEZERO)")
	out.write("\n# Column 2: CHANNEL (0-63)")
	out.write("\n# Column 3: PCUID (0-4)")
	out.write("\n# \n")

	for x,y,z in itertools.izip(good_time, good_chan, good_pcu):
		out.write("%.21f\t%d\t%d\n" % (x, y, z))
	out.close()
	
## End of function 'dat_out'


################################################################################
def fits_out(out_file, gti_file, event_list, data_header, good_time, good_chan,\
	good_pcu):
	"""
			fits_out
	
	Writes good events to a fits output file.
	
	"""
	
	print "Output file:", out_file
	
	######################
	## Making FITS header
	######################
	
	prihdr = fits.Header()
	prihdr = data_header
	prihdr.set('TYPE', "GTI`d event list")
	prihdr.set('RAW_EVT', event_list, "Decoded event list")
	prihdr.set('GTI_FILE', gti_file, "GTI file applied to decoded event list")
	prihdr.set('NOTES', 1, "TIMEZERO applied to TIME in Column 1.")
	prihdr.set('NOTES', 1, "")
	prihdu = fits.PrimaryHDU(header=prihdr)
	
	#####################
	## Making FITS table
	#####################
	
	col1 = fits.Column(name='TIME', unit='Hz', format='D', array=good_time)
	col2 = fits.Column(name='CHANNEL', unit='0-63)', format='I', array=good_chan)
	col3 = fits.Column(name='PCUID', unit='(0-4)', format='I', array=good_pcu)
	cols = fits.ColDefs([col1, col2, col3])
	tbhdu = fits.BinTableHDU.from_columns(cols)
	
	## If the file already exists, remove it
	assert out_file[-4:].lower() == "fits", \
		'ERROR: Standard output file must have extension ".fits".'
	if os.path.isfile(out_file):
		os.remove(out_file)
	
	############################
	## Writing to the FITS file
	############################
	
	thdulist = fits.HDUList([prihdu, tbhdu])
	thdulist.writeto(out_file)	
	
## End of function 'fits_out'
	

################################################################################
def main(event_list, gti_file, out_file):
	"""
			main
			
	Applies a GTI to an event list, to filter out events from bad times.
	
	"""
	
# 	print "Event list:", event_list
# 	print "GTI file:", gti_file

	timezero = float(get_key_val(event_list, 0, 'TIMEZERO'))
# 	assert int(get_key_val(gti_file, 1, 'PREFR')) == 0, \
# 		"\tERROR: Current configuration of program requires PREFR = 0"
# 	assert int(get_key_val(gti_file, 1, 'POSTFR')) == 1, \
# 		"\tERROR: Current configuration of program requires POSTFR = 1"
	
	data_hdu = fits.open(event_list)
	data_header = data_hdu[1].header	
	data = data_hdu[1].data
	orig_cols = data_hdu[1].columns
	data_hdu.close()
	
	gti = 0

	if gti_file[-4:].lower() == ".gti":
		gti_hdu = fits.open(gti_file)
		gti_header = gti_hdu[1].header	
		gti = gti_hdu[1].data
		gti_hdu.close()
	else:
		gti = np.loadtxt(gti_file)
	
	## OLD VERSION - Filtering based on PCU with boolean masks
# 	PCU2 = data.field('PCUID') == 2
# 	PCU0 = data.field('PCUID') == 0   
# 	data = data[np.ma.mask_or(PCU2,PCU0)]

	data_time = np.add(data.field('TIME'), timezero)
	data_chan = data.field('CHANNEL')
	data_pcu = data.field('PCUID')
	good_time = np.asarray([])
	good_chan = np.asarray([])
	good_pcu = np.asarray([])
	data_starttime = data_time[0]
	data_stoptime = data_time[-1]

	
	#########################
	## Filtering on GTI time
	#########################
	
	for t in gti:
	
		gti_start = t[0] + timezero # Front of the start-time-bin
		gti_stop = t[1] + timezero # Back of the end-time-bin

		if data_starttime < gti_start and \
			data_starttime < gti_stop and \
			data_stoptime < gti_start and \
			data_stoptime < gti_stop:
			
# 			print "Data stop before GTI starts."
			pass
			
		elif not (data_starttime > gti_start and \
				data_starttime > gti_stop and \
				data_stoptime > gti_start and \
				data_stoptime > gti_stop):
				
# 			print "GTI start and stop: %.21f, %.21f" % (gti_start, gti_stop)
			GTImask_start = data_time >= gti_start
			temp_a = data_time[GTImask_start]
			temp_b = data_chan[GTImask_start]
			temp_c = data_pcu[GTImask_start]
			GTImask_stop = temp_a <= gti_stop
			temp_time = temp_a[GTImask_stop]
			temp_chan = temp_b[GTImask_stop]
			temp_pcu = temp_c[GTImask_stop]

			assert np.shape(temp_time) == np.shape(temp_chan)
			assert np.shape(temp_chan) == np.shape(temp_pcu)
			
			good_time = np.concatenate((good_time, temp_time))
			good_chan = np.concatenate((good_chan, temp_chan))
			good_pcu = np.concatenate((good_pcu, temp_pcu))
			
# 			print "Len good_time =", len(good_time)
		
# 		if t.field(1) > endtimeoflist: 
# 			break

	## End of for-loop through GTI time blocks
		
	assert np.shape(good_time) == np.shape(good_chan)
	assert np.shape(good_chan) == np.shape(good_pcu)
	
	##########
	## Output 
	##########
	
	if out_file[-4:].lower() == "fits":
		fits_out(out_file, gti_file, event_list, data_header, good_time, \
			good_chan, good_pcu)
	elif out_file[-3:].lower() == "dat":
		dat_out(out_file, gti_file, event_list, good_time, good_chan, good_pcu)
	else:
		raise Exception("ERROR: File type of GTI'd event list must be .dat or .fits.")
 
 ## End of function 'main'


################################################################################
if __name__ == "__main__":
	
	parser = argparse.ArgumentParser(usage='applygti.py eventlist gtifile \
outfile', description='Applies a GTI (good time interval) to an RXTE decoded \
event list. Corrects for TIMEZERO. Does not select PCU.')
	
	parser.add_argument('eventlist', help="The full path of the decoded event \
list file.")
	
	parser.add_argument('gtifile', help="The full path of the (FITS) GTI file, \
made in HEASoft's 'maketime' script. This program assumes that a FITS-format \
GTI file will have the extension '.gti'.")
	
	parser.add_argument('outfile', help="Name of the .fits output file, to \
write the GTI'd event list to.")
	
	args = parser.parse_args()
	
	main(args.eventlist, args.gtifile, args.outfile)

## End of program 'apply_gti_fits.py'

################################################################################
