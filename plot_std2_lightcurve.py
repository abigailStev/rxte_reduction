import argparse
import numpy as np
from astropy.io import fits
import matplotlib.pyplot as plt
import os
import tools

__author__ = "Abigail Stevens"
__author_email__ = "A.L.Stevens@uva.nl"
__year__ = "2014-2015"
__description__ = "Plots the time-domain light curve of Standard-2 RXTE PCA \
data."

"""
		plot_std2_lightcurve.py

Written in Python 2.7.

All modules imported above, as well as python 2.7, can be downloaded in the 
Anaconda package. See https://store.continuum.io/cshop/anaconda/

"""

################################################################################
def main(prefix, obsID_list_file, plot_file):
	
	file_path = os.path.dirname(obsID_list_file).strip().split('/')
	file_prefix = "/".join(file_path[0:len(file_path)-2])+"/Reduced_data/"+prefix
	
	obsID_list = [line.strip() for line in open(obsID_list_file)]
	
	time_avg = []
	counts_avg = []

	###################################
	## Start of looping through obsIDs
	###################################
	
	for obsID in obsID_list:
	
		file = file_prefix+"/"+obsID+"/std2.lc"
		len_fname = len(file)
		time = []
		rate = []
		
		if file[len_fname - 3:len_fname].lower() == ".lc":
			fits_hdu = fits.open(file)
			header = fits_hdu[1].header	
			data = fits_hdu[1].data
			fits_hdu.close()
			time = data.field(0)
			counts = data.field(1)
			time_avg.append(np.mean(time))
			counts_avg.append(np.mean(counts))

		else:
			raise Exception("\tERROR: Light curve needs to be in FITS format with extension '.lc'. Exiting.")
			exit()

		if np.amax(counts) == 63:
			print "\n\t WARNING: Are you sure you're not plotting time vs energy channel?"
			
	## End of for-loop
	
	## Sorting the averaged lists, since obsIDs aren't necessarily in time order
	counts_avg_sorted = [y for (x,y) in sorted(zip(time_avg, counts_avg))]
	time_avg_sorted = sorted(time_avg)
	## Putting time into days
	time_avg_sorted = (time_avg_sorted - time_avg_sorted[0]) / 86400.0
	## 432000 elapsed seconds is 5 days
	## 86400 seconds is one day
	
	print "Standard-2 lightcurve: %s" % plot_file
	fig, ax = plt.subplots()
	ax.plot(time_avg_sorted, counts_avg_sorted, lw=3)
	ax.set_xlabel('Time elapsed (days)', fontsize=12)
	ax.set_ylabel('Average photon count', fontsize=12)
	ax.set_xlim(0, np.max(time_avg_sorted)+2)
	ax.set_ylim(np.min(counts_avg_sorted)-10, np.max(counts_avg_sorted)+10)
	ax.set_title(prefix+" Light Curve")	
	plt.savefig(plot_file, dpi=140)
# 	plt.show()
	plt.close()
	
## End of function 'main'


################################################################################
if __name__ == "__main__":
	
	parser = argparse.ArgumentParser(usage="plot_std2_lightcurve.py prefix \
obsID_list_file plot_file", description="Plots the time-domain light curve of a\
 whole data set.")

	parser.add_argument('prefix', help="Data set prefix / proposal ID.")
	
	parser.add_argument('obsID_list_file', help="Name of input text file with \
list of obsIDs for data to plot lightcurve of. One obsID per line.")

	parser.add_argument('plot_file', help="The output file name for the \
lightcurve plot.")

	args = parser.parse_args()

	main(args.prefix, args.obsID_list_file, args.plot_file)

## End of program 'plot_lightcurve.py'

################################################################################
