import numpy as np
import matplotlib.pyplot as plt
import matplotlib.font_manager as font_manager

in_file="/Users/abigailstevens/Reduced_data/GX339-BQPO/filters.dat"
out_file="filter_plot.png"

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


f = open(in_file, 'r')
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

x = np.arange(len(obsIDs))+0.5
pcus = np.column_stack((pcu0_on, pcu1_on, pcu2_on, pcu3_on, pcu4_on))

print "\nPCUs ON:"
for i in range(len(pcus_on)):
	print obsIDs[i],"\t",pcus_on[i]
print "("+str(len(obsIDs))+" obsIDs)"
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
plt.show()
plt.close()

