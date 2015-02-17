import numpy as np
import matplotlib.pyplot as plt
import matplotlib.font_manager as font_manager
from astropy.io import fits
import os
import sys
import argparse

"""
		pcu_filter.py
"""
################################################################################
def main(filter_list):

	data_dir="/Users/abigailstevens/Dropbox/Research/sample_data"
	# filter_list = data_dir+"/tmp_filters.txt"
	tab_file = data_dir+"/filters.dat"
	tab2_file = data_dir+"/filter_info.txt"
	out_file1 = data_dir+"/obsID_pcus.png"
	out_file2 = data_dir+"/pcus_on.png"
	filter_files = [line.strip() for line in open(filter_list)]

	num = len(filter_files)
	# print num

	font_prop = font_manager.FontProperties(size=8)
	i = 1
	#################################################
	for filter_file in filter_files:

		file_hdu = fits.open(filter_file)
		data = file_hdu[1].data
		obsID = file_hdu[0].header["OBS_ID"]
		file_hdu.close()
	
		## Need to start at 1 instead of 0, since place 0 has val=255 (the null val)
		time = data.field('TIME')[1:]
		time = (time - time[0]) / 60
	# 	print time
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
	
	# 	avg_time = np.mean(time)
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
	
	
		ax1 = plt.subplot(3, 4, i)
		ax1.plot(time, num_pcu, 'y-.', lw=4)
		ax1.plot(time, pcu2, 'k', lw=1)
		ax1.plot(time, pcu0, 'r--', lw=3)
		ax1.plot(time, pcu1, 'b:', lw=3)
		ax1.plot(time, pcu3, 'g--', lw=2)
		ax1.plot(time, pcu4, 'm:', lw=2)
		ax1.set_ylim(0, np.max(num_pcu)+0.25)
		ax1.set_xlabel("Time (minutes)", fontproperties=font_prop)
		ax1.tick_params(axis='x', labelsize=8)
		ax1.tick_params(axis='y', labelsize=8)
		ax1.set_title(obsID, fontsize=10)
	
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

		out_str = obsID+"\t"+str(num_pcu_on)+"\t"+\
			str(avg_pcu_on)+"\t"+pcus_on+"\t"+str(pcu0_on)+"\t"+str(pcu0_avg)+"\t"+\
			str(pcu1_on)+"\t"+str(pcu1_avg)+"\t"+str(pcu2_on)+"\t"+str(pcu2_avg)+\
			"\t"+str(pcu3_on)+"\t"+str(pcu3_avg)+"\t"+str(pcu4_on)+"\t"+\
			str(pcu4_avg)+"\n"
	
		with open(tab_file, 'a') as out:
			out.write(out_str)
		
		i += 1
	
	plt.tight_layout()
	plt.savefig(out_file1, dpi=300)
	# plt.show()
	plt.close()

	#################################################

	obsIDs = []
	num_pcus_on = np.asarray([])
	avg_pcus_on = np.asarray([])
	pcus_on = []
	pcu0_on = np.asarray([])
	pcu0_avg = np.asarray([])
	pcu1_on = np.asarray([])
	pcu1_avg = np.asarray([])
	pcu2_on = np.asarray([])
	pcu2_avg = np.asarray([])
	pcu3_on = np.asarray([])
	pcu3_avg = np.asarray([])
	pcu4_on = np.asarray([])
	pcu4_avg = np.asarray([])


	f = open(tab_file, 'r')
	for line in f:
		line = line.strip().split()
	# 	print line
		obsIDs.append(str(line[0]))
		num_pcus_on = np.append(num_pcus_on, int(line[1]))
		avg_pcus_on = np.append(avg_pcus_on, float(line[2]))
		pcus_on.append(str(line[3]))
		pcu0_on = np.append(pcu0_on, int(line[4]))
		pcu0_avg = np.append(pcu0_avg, float(line[5]))
		pcu1_on = np.append(pcu1_on, int(line[6]))
		pcu1_avg = np.append(pcu1_avg, float(line[7]))
		pcu2_on = np.append(pcu2_on, int(line[8]))
		pcu2_avg = np.append(pcu2_avg, float(line[9]))
		pcu3_on = np.append(pcu3_on, int(line[10]))
		pcu3_avg = np.append(pcu3_avg, float(line[11]))
		pcu4_on = np.append(pcu4_on, int(line[12]))
		pcu4_avg = np.append(pcu4_avg, float(line[13]))

	x = np.arange(num)+0.5
	# pcus = np.column_stack((pcu0_on, pcu1_on, pcu2_on, pcu3_on, pcu4_on))
	pcu0_sum = int(np.sum(pcu0_on))
	pcu1_sum = int(np.sum(pcu1_on))
	pcu2_sum = int(np.sum(pcu2_on))
	pcu3_sum = int(np.sum(pcu3_on))
	pcu4_sum = int(np.sum(pcu4_on))
	pcu_sums = [pcu0_sum, pcu1_sum, pcu2_sum, pcu3_sum, pcu4_sum]

	with open (tab2_file, 'w') as out:
		out.write("PCUs ON:")
		for i in range(num):
			out.write("\n"+obsIDs[i]+"\t"+str(pcus_on[i]))
		out.write("\n("+str(num)+" obsIDs)")
		out.write("\n\n   PCUs: 0  1   2  3  4")
		out.write("\n\t"+str(pcu_sums)+"\n")

	if len(num_pcus_on) > num:
		num_pcus_on = num_pcus_on[-12]

	font_prop = font_manager.FontProperties(size=16)
	fig, ax = plt.subplots(1,1,figsize=(7,6))
	ax.plot(num_pcus_on, x, '*', ms=10)
	ax.hlines(x, [0], num_pcus_on, linestyles='dotted', lw=3)
	ax.set(xlim=(0,5.1), yticks=x, yticklabels=obsIDs, \
		xlabel="Maximum number of PCUs on during obsID")
	ax.tick_params(axis='y', labelsize=10)
	fig.set_tight_layout(True)
	plt.savefig(out_file2, dpi=150)
	# plt.show()	
	plt.close()
	
## End of function 'main'


################################################################################
if __name__ == "__main__":
	
	parser = argparse.ArgumentParser(usage='', description='', epilog='')
	parser.add_argument('filter_list', help='List of filter files.')
	args = parser.parse_args()
	
	main(args.filter_list)

################################################################################
