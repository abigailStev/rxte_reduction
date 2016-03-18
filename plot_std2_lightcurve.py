
"""
Plots the time-domain light curve of Standard-2 RXTE PCA data.

"""

import argparse
import numpy as np
from astropy.io import fits
import matplotlib.pyplot as plt
import os
import tools

__author__ = "Abigail Stevens <A.L.Stevens@uva.nl>"
__year__ = "2014-2016"


################################################################################
# def main(prefix, obsID_list_file, plot_file="./std2_lc.png"):
def main(prefix, all_std2_lc_file, plot_file="./std2_lc.png"):

    """
    Main of plot_std2_lightcurve.py.

    Parameters
    ----------
    prefix : str
        The identifying prefix of the data (object nickname or data ID).

    all_std2_lc_file : str
        A light curve file extracted from all the Standard2 data together.

    plot_file : str, default='std2_lc.png'
        The name of the plot file to save the std2 lightcurve to.

    Returns
    -------
    Nothing, but saves to plot_file.

    """

    assert os.path.exists(all_std2_lc_file)

    # file_path = os.path.dirname(obsID_list_file).strip().split('/')
    # file_prefix = "/".join(file_path[0:len(file_path)-2]) + \
    #               "/Reduced_data/" + prefix
    #
    # obsID_list = [line.strip() for line in open(obsID_list_file)]

    time_avg = []
    counts_avg = []

    ###################################
    ## Start of looping through obsIDs
    ###################################
    # for obsID in obsID_list:
    # file = file_prefix + "/" + obsID + "/all_std2.lc"
    file = all_std2_lc_file
    len_fname = len(file)
    # time = []
    # rate = []
    if file[len_fname - 3:len_fname].lower() == ".lc":
        fits_hdu = fits.open(file)
        # header = fits_hdu[1].header
        data = fits_hdu[1].data
        fits_hdu.close()
        time = data.field(0)
        counts = data.field(1)
        time_avg.append(np.mean(time))
        counts_avg.append(np.mean(counts))
    else:
        raise Exception("\tERROR: Light curve needs to be in FITS format "\
                        "with extension '.lc'. Exiting.")

    if np.amax(counts) == 63:
        print "\n\t WARNING: Are you sure you're not plotting time vs energy channel?"

    ## Sorting the averaged lists, since obsIDs aren't necessarily in time order
    # counts_avg_sorted = [y for (x,y) in sorted(zip(time_avg, counts_avg))]
    # time_avg_sorted = sorted(time_avg)

    time_avg_sorted = time
    counts_avg_sorted = counts

    ## Putting time into days
    time_avg_sorted = (time_avg_sorted - time_avg_sorted[0]) / 86400.0
    ## 432000 elapsed seconds is 5 days
    ## 86400 seconds is one day

    print "Standard-2 lightcurve: %s" % plot_file
    fig, ax = plt.subplots(1, 1, figsize=(10,7.5), dpi=200)
    ax.plot(time_avg_sorted, counts_avg_sorted, lw=3)
    ax.set_xlabel('Time elapsed (days)', fontsize=18)
    ax.set_ylabel('Average photon count', fontsize=18)
    ax.set_xlim(0, np.max(time_avg_sorted))
    ax.set_ylim(np.min(counts_avg_sorted)-10, np.max(counts_avg_sorted)+10)
    ax.tick_params(axis='x', labelsize=18)
    ax.tick_params(axis='y', labelsize=18)
    title = "%s Lightcurve" % (prefix)
    ax.set_title(title, fontsize=18)

    plt.savefig(plot_file)
    plt.show()
    plt.close()


################################################################################
if __name__ == "__main__":

    parser = argparse.ArgumentParser(usage="plot_std2_lightcurve.py prefix "\
            "obsID_list_file plot_file", description="Plots the time-domain "\
            "light curve of a whole data set.")

    parser.add_argument('prefix', help="The identifying prefix of the data "\
            "(object nickname or data ID).")

    # parser.add_argument('obsID_list_file', help="Name of input text file with "\
    #         "list of obsIDs for data to plot lightcurve of. One obsID per "\
    #         "line.")

    parser.add_argument('all_std2_lc_file')

    parser.add_argument('plot_file', default="./std2_lc.png",
            help="The output file name for the lightcurve plot.")

    args = parser.parse_args()

    # main(args.prefix, args.obsID_list_file, plot_file=args.plot_file)
    main(args.prefix, args.all_std2_lc_file, plot_file=args.plot_file)

################################################################################
