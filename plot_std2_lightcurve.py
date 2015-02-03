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

##############################
def main(propID, obsID_list_file, plot_file):
	pass
	
	file_path = os.path.dirname(obsID_list_file).strip().split('/')
	file_prefix = "/".join(file_path[0:len(file_path)-1])+"/Reduced_data/"+propID
	obsID_list = [line.strip() for line in open(obsID_list_file)]
	start_time = np.float64(tools.get_key_val(file_prefix+"/"+obsID_list[0]+"/std2.lc", 0, "TSTART"))
	print "%.21f" % start_time
	
	end_time = 0
	fig, ax = plt.subplots()
	time_avg = []
	counts_avg = []
	
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
			time = (data.field(0) - start_time) / float(86400) # converting to days
	# 			time = data.field(0) - start_time
			counts = data.field(1)
	# 			ax.plot(time, counts, lw=3, label=obsID)
			time_avg.append(np.mean(time))
			counts_avg.append(np.mean(counts))
			if time[len(time)-1] > end_time:
				end_time = time[len(time)-1]
		else:
# 			print "\n\t ERROR: ASCII doesn't work with this iteration of plot_std2_lightcurve.py, since we don't know how far apart the end of one light curve is from the beginning of the next. See evernote for previous version of program. Exiting."
			print "\n\t ERROR: Data file needs to be in FITS format with extension '.lc'. Exiting."
			exit()

		if np.amax(counts) == 63:
			print "\n\t WARNING: Are you sure you're not plotting time vs energy channel?"
	## End of for-loop
	
	## Sorting the averaged lists, since obsIDs aren't necessarily in time order
	counts_avg_sorted = [y for (x,y) in sorted(zip(time_avg, counts_avg))]
	time_avg_sorted = sorted(time_avg)
	ax.plot(time_avg_sorted, counts_avg_sorted, lw=3)
	
	plt.xlabel('Time elapsed since start of first observation', fontsize=12)
	plt.ylabel('Average photon count', fontsize=12)
	plt.xlim(0, )
	title = propID+" light curve"
	plt.title(title)
	
	# 432000 elapsed seconds is 5 days
	# 86400 seconds is one day
	
	## The following legend code was found on stack overflow I think, or a pyplot tutorial
# 	legend = ax.legend(loc='upper right')
# 	for label in legend.get_texts():
# 		 label.set_fontsize(6)
# 	for label in legend.get_lines():
# 		 label.set_linewidth(2)  # the legend line width
	
	plt.savefig(plot_file, dpi=140)
	print "Plot saved to %s" % plot_file
# 	plt.show()
	plt.close()
	
## End of function 'main'


##########################
if __name__ == "__main__":
	
	parser = argparse.ArgumentParser(description="Plots the time-domain light curve.")
	parser.add_argument('propID', help="Proposal ID.")
	parser.add_argument('obsID_list_file', \
		help="Name of input text file with list of obsIDs for data to plot lightcurve of. One obsID per line.")
	parser.add_argument('plot_file', \
		help="The output file name for the lightcurve plot.")
	args = parser.parse_args()

	main(args.propID, args.obsID_list_file, args.plot_file)

## End of program 'plot_lightcurve.py'