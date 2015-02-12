import numpy as np
import matplotlib.pyplot as plt
import matplotlib.font_manager as font_manager
from astropy.io import fits
import os
import sys

"""
		pcu_filter.py
"""

filter_list = "/Users/abigailstevens/Reduced_data/GX339-BQPO/tmp_filters.txt"
tab_file = "/Users/abigailstevens/Reduced_data/GX339-BQPO/filters.dat"
out_file = "/Users/abigailstevens/Reduced_data/GX339-BQPO/pcus_on.png"
filter_files = [line.strip() for line in open(filter_list)]

num = len(filter_files)
print num

font_prop = font_manager.FontProperties(size=16)
# fig, ax = plt.subplots(4, 3)
row=1
col=1
i=1
#################################################
for filter_file in filter_files:

	file_hdu = fits.open(filter_file)
	data = file_hdu[1].data
	obsID = file_hdu[0].header["OBS_ID"]
	file_hdu.close()
	
	## Need to start at 1 instead of 0, since place 0 has val=255 (the null val)
	time = data.field('TIME')[1:]
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
	
	avg_time = np.mean(time)
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
	
# 	print row, col
	
# 	ax = plt.subplot(num, row, col)
	ax = plt.subplot(3, 4, i)
	ax.plot(time, num_pcu, '--')
	ax.set_ylim(0, np.max(num_pcu)+0.25)
	ax.set_title(obsID)
	
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

	out_str = obsID+"\t"+str(avg_time)+"\t"+str(num_pcu_on)+"\t"+\
		str(avg_pcu_on)+"\t"+pcus_on+"\t"+str(pcu0_on)+"\t"+str(pcu0_avg)+"\t"+\
		str(pcu1_on)+"\t"+str(pcu1_avg)+"\t"+str(pcu2_on)+"\t"+str(pcu2_avg)+\
		"\t"+str(pcu3_on)+"\t"+str(pcu3_avg)+"\t"+str(pcu4_on)+"\t"+\
		str(pcu4_avg)+"\n"
	
	with open(tab_file, 'a') as out:
		out.write(out_str)
		
	row += 1
	col += 1
	i += 1
	if row % 4 == 0:
		row = 1
	if col % 5 == 0:
		col = 1
	
plt.tight_layout()
plt.show()

#################################################

obsIDs = []
time = np.asarray([])
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
	time = np.append(time, float(line[1]))
	num_pcus_on = np.append(num_pcus_on, int(line[2]))
	avg_pcus_on = np.append(avg_pcus_on, float(line[3]))
	pcus_on.append(str(line[4]))
	pcu0_on = np.append(pcu0_on, int(line[5]))
	pcu0_avg = np.append(pcu0_avg, float(line[6]))
	pcu1_on = np.append(pcu1_on, int(line[7]))
	pcu1_avg = np.append(pcu1_avg, float(line[8]))
	pcu2_on = np.append(pcu2_on, int(line[9]))
	pcu2_avg = np.append(pcu2_avg, float(line[10]))
	pcu3_on = np.append(pcu3_on, int(line[11]))
	pcu3_avg = np.append(pcu3_avg, float(line[12]))
	pcu4_on = np.append(pcu4_on, int(line[13]))
	pcu4_avg = np.append(pcu4_avg, float(line[14]))

x = np.arange(num)+0.5
pcus = np.column_stack((pcu0_on, pcu1_on, pcu2_on, pcu3_on, pcu4_on))

print "\nPCUs ON:"
for i in range(num):
	print obsIDs[i],"\t",pcus_on[i]
print "("+str(num)+" obsIDs)"
pcu0_sum = int(np.sum(pcu0_on))
pcu1_sum = int(np.sum(pcu1_on))
pcu2_sum = int(np.sum(pcu2_on))
pcu3_sum = int(np.sum(pcu3_on))
pcu4_sum = int(np.sum(pcu4_on))

pcu_sums = [pcu0_sum, pcu1_sum, pcu2_sum, pcu3_sum, pcu4_sum]
print "\n   PCUs: 0  1   2  3  4"
print "\t",pcu_sums, "\n"


font_prop = font_manager.FontProperties(size=16)
fig, ax = plt.subplots(1,1,figsize=(8,6))
ax.plot(num_pcus_on, x, 'x')
ax.hlines(x, [0], num_pcus_on, linestyles='dotted', lw=3)
ax.set(xlim=(0,5.1), yticks=x, yticklabels=obsIDs, xlabel="Maximum number of PCUs on during obsID")
plt.tight_layout()
plt.savefig(out_file, dpi=150)
# plt.show()
	

plt.close()

