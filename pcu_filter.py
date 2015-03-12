import numpy as np
import matplotlib.pyplot as plt
import matplotlib.font_manager as font_manager
from astropy.io import fits
import os
import sys
import argparse

"""
		pcu_filter.py

Written in python 2.7.

"""
################################################################################
def main(filter_list, prefix, data_dir):
	
	###################
	## Initializations
	###################
	
	tab_file = data_dir+"/"+prefix+"_filters.dat"
	tab2_file = data_dir+"/"+prefix+"_filter_info.txt"
	out_file1 = data_dir+"/"+prefix+"_obsID_pcus.png"
	out_file2 = data_dir+"/"+prefix+"_pcus_on.png"
	filter_files = [line.strip() for line in open(filter_list)]
	num = len(filter_files)
	obsIDs = []
	num_pcus_on_array = np.asarray([])
	avg_pcus_on_array = np.asarray([])
	pcus_on_list = []
	pcu0_on_array = np.asarray([])
	pcu0_avg_array = np.asarray([])
	pcu1_on_array = np.asarray([])
	pcu1_avg_array = np.asarray([])
	pcu2_on_array = np.asarray([])
	pcu2_avg_array = np.asarray([])
	pcu3_on_array = np.asarray([])
	pcu3_avg_array = np.asarray([])
	pcu4_on_array = np.asarray([])
	pcu4_avg_array = np.asarray([])
	i = 1
	
	font_prop = font_manager.FontProperties(size=8)
	
	####################################
	## Looping through the filter files
	####################################
	
	for filter_file in filter_files:
		try:
			file_hdu = fits.open(filter_file)
		except IOError:
			print "\tERROR: File does not exist: %s" % filter_file
			continue
			
		data = file_hdu[1].data
		obsID = file_hdu[0].header["OBS_ID"]
		file_hdu.close()
	
		## Need to start at 1 instead of 0, since [0]=255 (the null val)
		time = data.field('TIME')[1:]
		time = (time - time[0]) / 60
		elv = data.field('ELV')[1:]
		tssaa = data.field('TIME_SINCE_SAA')[1:]
		offset = data.field('OFFSET')[1:]
		electron2 = data.field('ELECTRON2')[1:]
		num_pcu = data.field('NUM_PCU_ON')[1:]
		pcu0 = data.field('PCU0_ON')[1:]
		pcu1 = data.field('PCU1_ON')[1:]
		pcu2 = data.field('PCU2_ON')[1:]
		pcu3 = data.field('PCU3_ON')[1:]
		pcu4 = data.field('PCU4_ON')[1:]
	
		num_pcu_on = np.max(num_pcu)
		avg_pcu_on = np.mean(num_pcu)
		pcu0_on = np.max(pcu0)
		pcu0_avg = np.mean(pcu0)
		pcu1_on = np.max(pcu1)
		pcu1_avg = np.mean(pcu1)
		pcu2_on = np.max(pcu2)
		pcu2_avg = np.mean(pcu2)
		pcu3_on = np.max(pcu3)
		pcu3_avg = np.mean(pcu3)
		pcu4_on = np.max(pcu4)
		pcu4_avg = np.mean(pcu4)
	
	
# 		ax1 = plt.subplot(3, 4, i)
# 		ax1.plot(time, num_pcu, 'y-.', lw=4)
# 		ax1.plot(time, pcu2, 'k', lw=1)
# 		ax1.plot(time, pcu0, 'r--', lw=3)
# 		ax1.plot(time, pcu1, 'b:', lw=3)
# 		ax1.plot(time, pcu3, 'g--', lw=2)
# 		ax1.plot(time, pcu4, 'm:', lw=2)
# 		ax1.set_ylim(0, np.max(num_pcu)+0.25)
# 		ax1.set_xlabel("Time (minutes)", fontproperties=font_prop)
# 		ax1.tick_params(axis='x', labelsize=8)
# 		ax1.tick_params(axis='y', labelsize=8)
# 		ax1.set_title(obsID, fontsize=10)
		i += 1

		pcus_on = ""
		if pcu0_on > 0:
			pcus_on+="0"
		if pcu1_on > 0:
			pcus_on+="1"
		if pcu2_on > 0:
			pcus_on+="2"
		if pcu3_on > 0:
			pcus_on+="3"
		if pcu4_on > 0:
			pcus_on+="4"
	
		obsIDs.append(obsID)
		num_pcus_on_array = np.append(num_pcus_on_array, num_pcu_on)
		avg_pcus_on_array = np.append(avg_pcus_on_array, avg_pcu_on)
		pcus_on_list.append(pcus_on)
		pcu0_on_array = np.append(pcu0_on_array, pcu0_on)
		pcu0_avg_array = np.append(pcu0_avg_array, pcu0_avg)
		pcu1_on_array = np.append(pcu1_on_array, pcu1_on)
		pcu1_avg_array = np.append(pcu1_avg_array, pcu1_avg)
		pcu2_on_array = np.append(pcu2_on_array, pcu2_on)
		pcu2_avg_array = np.append(pcu2_avg_array, pcu2_avg)
		pcu3_on_array = np.append(pcu3_on_array, pcu3_on)
		pcu3_avg_array = np.append(pcu3_avg_array, pcu3_avg)
		pcu4_on_array = np.append(pcu4_on_array, pcu4_on)
		pcu4_avg_array = np.append(pcu4_avg_array, pcu4_avg)
	
	## End of for loop through filter files
	
# 	plt.tight_layout()
# 	plt.savefig(out_file1, dpi=300)
# 	# plt.show()
# 	plt.close()

	tmp = np.arange(num)+0.5
	pcu_stack = np.column_stack((pcu0_on_array, pcu1_on_array, pcu2_on_array, \
		pcu3_on_array, pcu4_on_array))
	pcu_sums = np.sum(pcu_stack, axis=0)
	pcus = np.arange(5)

	######################################################################
	## Writing summary to a text file for easy human-reading and printing
	######################################################################
	
	with open (tab2_file, 'w') as out:
		out.write("PCUs ON:")
		for i in range(num):
			out.write("\n"+obsIDs[i]+"\t"+str(pcus_on_list[i]))
		out.write("\n("+str(num)+" obsIDs)")
		out.write("\n")
		out.write("\nPCUs:")
		for (pcu, element) in zip(pcus, pcu_sums):
			out.write("\n\t"+str(pcu)+"\t"+str(int(element)))
		out.write("\n")

	if len(num_pcus_on_array) > num:
		num_pcus_on_array = num_pcus_on_array[-num]
	
	########################################
	## Plotting number of pcus on per obsID
	########################################
	
	if num <= 100:
		fs = (8,8)
	elif num <= 160:
		fs = (8,16)
	else:
		fs = (8,20)
		
	font_prop = font_manager.FontProperties(size=16)
	fig, ax = plt.subplots(1,1,figsize=fs)
	ax.plot(num_pcus_on_array, tmp, '*', ms=10)
	ax.hlines(tmp, [0], num_pcus_on_array, linestyles='dotted', lw=3)
	ax.set(xlim=(0,5.1), ylim=(0, np.max(tmp)+0.5), yticks=tmp, \
		yticklabels=obsIDs, xlabel="Maximum number of PCUs on during obsID")
	ax.tick_params(axis='y', labelsize=10)
	fig.set_tight_layout(True)
	plt.savefig(out_file2, dpi=200)
	# plt.show()	
	plt.close()
	
## End of function 'main'


################################################################################
if __name__ == "__main__":
	
	##############################################
	## Parsing input arguments and calling 'main'
	##############################################
	
	parser = argparse.ArgumentParser(usage='', description='', epilog='')
	parser.add_argument('filter_list', help="List of filter files.")
	parser.add_argument('prefix', help="Prefix of data set.")
	parser.add_argument('data_dir', help="Directory of reduced data.")
	args = parser.parse_args()
	
	main(args.filter_list, args.prefix, args.data_dir)

################################################################################
