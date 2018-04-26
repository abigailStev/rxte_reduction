import argparse
import numpy as np
import matplotlib.pyplot as plt
from astropy.io import fits
import matplotlib.font_manager as font_manager
import subprocess

dt = 0.0078125

in_file = "/Users/abigailstevens/Dropbox/Research/simulate/out_sim/TK_lightcurve_nopoiss.dat"
plot_file = '/Users/abigailstevens/Dropbox/Research/simulate/out_sim/TK_lightcurve_nopoiss.png'
plot_title = "FAKE-TK-GX339B lightcurve chunk, no Poisson noise"

# in_file = "/Users/abigailstevens/Dropbox/Research/simulate/out_sim/TK_lightcurve_wpoiss.dat"
# plot_file = '/Users/abigailstevens/Dropbox/Research/simulate/out_sim/TK_lightcurve_wpoiss.png'
# plot_title = "FAKE-TK-GX339B lightcurve chunk, with Poisson noise"


# in_file = "/Users/abigailstevens/Dropbox/Research/cross_correlation/GX339-BQPO_ref_lc.dat"
# plot_file = "/Users/abigailstevens/Dropbox/Research/cross_correlation/GX339-BQPO_ref_lc.png"
# plot_title = "GX339-BQPO lightcurve chunk"


table = np.loadtxt(in_file)
print np.shape(table)

time_bins = table[:,0]
lightcurve = table[:,1]
# lightcurve = table
# time_bins = np.arange(len(lightcurve))

mean_rate = np.mean(lightcurve)

var = np.sum(lightcurve * dt)
rms = np.sqrt(var)
print var / mean_rate ** 2
print rms / mean_rate



fig, ax = plt.subplots(1, 1, figsize=(15,10))  ## figsize=(width, height)
ax.plot(time_bins, lightcurve, lw=2)
ax.set_xlabel(r"Time bins ($\times\,\frac{1}{128}\,$s)")
ax.set_ylabel("Count rate (photons/s)")
ax.plot([0, len(lightcurve)],[mean_rate,mean_rate], lw=1.5, ls='dashed', c='black')
# ax.set_xlim(len(lightcurve)-3000, len(lightcurve))
ax.set_xlim(0, 500)
ax.set_ylim(0, 3000)
ax.set_title(plot_title)
plt.savefig(plot_file)
plt.close()

subprocess.call(["open", plot_file])