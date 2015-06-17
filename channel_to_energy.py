import numpy as np
import argparse
import os.path

import tools  # in https://github.com/abigailStev/whizzy_scripts

__author__ = "Abigail Stevens, A.L.Stevens at uva.nl"
__version__ = "0.2 2015-06-16"

"""
Converts an RXTE energy channel list to a list of real energy *boundaries* per
detector mode energy channel.

Use this for plotting 2D CCF and lag-energy spectra vs energy in keV instead of
vs detector mode energy channel.

Abigail Stevens, A.L.Stevens at uva.nl, 2015

"""

################################################################################
if __name__ == "__main__":

    ###########################
    ## Parsing input arguments
    ###########################

    parser = argparse.ArgumentParser(usage="channel_to_energy.py ec_table_file"\
            " chan_bin_file out_file", description="Converts an RXTE energy "\
            "channel list to a list of real energy *boundaries* per detector "\
            "energy channel.", epilog="All arguments are required.")

    parser.add_argument('ec_table_file', help="Txt table with energy in keV to"\
            " absolute channel conversion for RXTE.")

    parser.add_argument('chan_bin_file', help="Txt table with how many "\
            "absolute channels to group together for each mode energy channel.")

    parser.add_argument('out_file', help="Output file (.txt) for real energy "\
            "boundaries per detector energy channel.")

    parser.add_argument('obs_epoch', type=tools.type_positive_int, help="RXTE "\
            "observation epoch.")

    args = parser.parse_args()

    ## Idiot checks
    assert os.path.isfile(args.ec_table_file), "ERROR: Energy-to-channel "\
            "conversion table does not exist."
    assert os.path.isfile(args.chan_bin_file), "ERROR: Channel binning file "\
            "does not exist."
    assert args.obs_epoch <= 5, "ERROR: Invalid observation epoch. Must be an "\
            "int between 1 and 5, inclusive."

    #############################
    ## Loading tables from files
    #############################
    ec_table = np.loadtxt(args.ec_table_file)
    chan_bin_table = np.loadtxt(args.chan_bin_file)

    ## Determining column for ec_table based on observation epoch
    if args.obs_epoch <= 4:
        ec_col = args.obs_epoch + 1
    else:
        ec_col = 7

    ## Extracting specific columns (these numbers don't change)
    energies = ec_table[:, ec_col]  ## Column with the energy in keV per absolute
                                    ## channel
    binning = chan_bin_table[:, 2]  ## Column telling how many absolute channels
                                    ## to bin together for that energy bin

    ## Initializations
    energies = np.append(energies, energies[-1])
    energy_array = np.asarray(energies[0])
    prev_ind = 0

    ############################################
    ## Looping through the energy binning array
    ############################################

    for amt in binning:
        en_bin_bound = np.mean(energies[prev_ind + amt - 1:prev_ind + amt + 1])
        energy_array = np.append(energy_array, en_bin_bound)
        prev_ind += amt

    ## Chop off the last one to have the correct amount of values in the list
    energy_array = energy_array[0:-1]

    ####################################
    ## Output energy array to text file
    ####################################

    np.savetxt(args.out_file, energy_array)

################################################################################
