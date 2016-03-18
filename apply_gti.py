#!/usr/bin/env python

"""
Applies a GTI to an RXTE decoded event list, to filter out events in bad times.
This code assumes that the GTI times have not been previously corrected with
TIMEZERO, but does assume the start time is at the front of the first time bin
and the end time is at the end of the last time bin. Does not select on PCU.

"""

import argparse
import numpy as np
from astropy.io import fits
import itertools
import os
from astropy.table import Table, Column

__author__ = "Abigail Stevens <A.L.Stevens at uva.nl>"
__version__ = "0.2 2015-06-17"
__year__ = "2014-2016"


################################################################################
def dat_out(out_file, gti_file, event_list, detchans, good_time, good_chan, \
        good_pcu):
    """
    Writes good events to a .dat output file.

    Parameters
    ----------
    out_file : str
        Filename of the .dat output file to write the good events to.

    gti_file : str
        Filename of the GTI (good times interval) file.

    event_list : str
        Filename of the unfiltered event list.

    detchans : int
        Number of energy channels for the detector mode.

    good_time : np.array of floats
        Times for good events.

    good_chan : np.array of ints
        Detector mode energy channels for good events.

    good_pcu : np.array of ints
        PCUs for good events.

    Returns
    -------
    nothing
    """

    print "Output file:", out_file

    with open(out_file, 'w') as out:
        out.write("# \tCreated in apply_gti.py")
        out.write("\n# Decoded event list: %s" % event_list)
        out.write("\n# GTI applied: %s" % gti_file)
        out.write("\n# DETCHANS = %d" % detchans)
        out.write("\n# ")
        out.write("\n# Column 1: TIME (corrected with TIMEZERO)")
        out.write("\n# Column 2: CHANNEL (0-DETCHANS)")
        out.write("\n# Column 3: PCUID (0-4)")
        out.write("\n# \n")

        for x,y,z in itertools.izip(good_time, good_chan, good_pcu):
            out.write("%.21f\t%d\t%d\n" % (x, y, z))

#
# ################################################################################
# def fits_out(out_file, gti_file, event_list, detchans, data_header, good_time, \
#         good_chan, good_pcu):
#     """
#     Writes good events to a FITS output file.
#
#     Parameters
#     ----------
#     out_file : str
#         Filename of the FITS output file to write the good events to.
#
#     gti_file : str
#         Filename of the GTI (good times interval) file.
#
#     event_list : str
#         Filename of the unfiltered event list.
#
#     detchans : int
#         Number of energy channels for the detector mode.
#
#     data_header : astropy.io.fits header object
#         FITS header of the input event list.
#
#     good_time : np.array of floats
#         Times for good events.
#
#     good_chan : np.array of ints
#         Detector mode energy channels for good events.
#
#     good_pcu : np.array of ints
#         PCUs for good events.
#
#     Returns
#     -------
#     nothing
#     """
#
#     print "Output file:", out_file

    ######################
    ## Making FITS header
    ######################
    # time_del = data_header['TIMEDEL']
    # print time_del
    # try:
    #     time_del = float(time_del)
    # except:
    #     time_del = float(time_del.split('/')[0])
    # print time_del
    # data_header['TIMEDEL'] = time_del
    #
    # prihdr = data_header
    # prihdr.set('TYPE', "GTI`d event list")
    # prihdr.set('RAW_EVT', event_list, "Decoded event list")
    # prihdr.set('GTI_FILE', gti_file, "GTI file applied to decoded event list")
    # prihdr.set('NOTES', 1, "TIMEZERO applied to TIME in Column 1.")
    # prihdr.set('DETCHANS', detchans, "Total number of detector energy channels"\
    #         " available")
    # prihdu = fits.PrimaryHDU(header=prihdr)

    #####################
    ## Making FITS table
    #####################
    #
    # col1 = fits.Column(name='TIME', unit='Hz', format='D', array=good_time)
    # col2 = fits.Column(name='CHANNEL', unit='(0-DETCHANS)', format='I', \
    #         array=good_chan)
    # col3 = fits.Column(name='PCUID', unit='(0-4)', format='I', array=good_pcu)
    # cols = fits.ColDefs([col1, col2, col3])
    # tbhdu = fits.BinTableHDU.from_columns(cols)

    # ## If the file already exists, remove it
    # assert out_file[-4:].lower() == "fits", "ERROR: Standard output file must "\
    #         "have extension '.fits'."
    # if os.path.isfile(out_file):
    #     os.remove(out_file)
    #
    # ############################
    # ## Writing to the FITS file
    # ############################
    #
    # thdulist = fits.HDUList([prihdu, tbhdu])
    # thdulist.writeto(out_file)


################################################################################
def main(event_list, gti_file, out_file):
    """
    Applies a GTI to an event list, to filter out events from bad times.

    Parameters
    ----------
    event_list : str
        Filename of the FITS file containing an unfiltered event list.

    gti_file : str
        Filename of the GTI (good times interval) file, in FITS or txt format.

    out_file : str
        Filename of the FITS file to save the good events to.

    Returns
    -------
    nothing

    Raises
    ------
    IOError if the event list doesn't exist or isn't a FITS file.

    IOError if the GTI file has extension .gti but isn't in FITS format.

    """

    #########################
    ## Opening the eventlist
    #########################

    try:
        data_hdu = fits.open(event_list)
    except IOError:
        print "\tERROR: File does not exist: %s" % event_list
        exit()

    out_table = Table()
    out_table.meta = data_hdu[1].header
    data = data_hdu[1].data
    orig_cols = data_hdu[1].columns
    data_hdu.close()

    out_table.meta['TYPE'] = "GTI`d event list"
    out_table.meta['RAW_EVT'] = event_list
    out_table.meta['GTI_FILE'] = gti_file
    out_table.meta['NOTES'] = "TIMEZERO applied to TIME in Column 1."


    ###########################################################
    ## Getting TIMEZERO the number of detector energy channels
    ###########################################################

    if '64M' in out_table.meta['DATAMODE'] and 'E_' in out_table.meta['DATAMODE']:
        detchans = 64
    elif '32M' in out_table.meta['DATAMODE'] and 'E_' in out_table.meta['DATAMODE']:
        detchans = 32
    elif '16B' in out_table.meta['DATAMODE'] and 'E_' in out_table.meta['DATAMODE']:
        detchans = 16
    elif 'Standard' in out_table.meta['DATAMODE']:
        detchans = 129
    else:
        detchans = 256

    out_table.meta['DETCHANS'] = detchans

    ########################
    ## Opening the GTI file
    ########################

    if gti_file[-4:].lower() == ".gti":
        try:
            gti_hdu = fits.open(gti_file)
        except IOError:
            print "\tERROR: File does not exist: %s" % gti_file
            exit()

        gti_header = gti_hdu[1].header
        gti = gti_hdu[1].data
        gti_hdu.close()
    else:
        gti = np.loadtxt(gti_file)

    ## OLD VERSION - Filtering based on PCU with boolean masks
# 	PCU2 = data.field('PCUID') == 2
# 	PCU0 = data.field('PCUID') == 0   
# 	data = data[np.ma.mask_or(PCU2,PCU0)]

    data_time = np.add(data.field('TIME'), out_table.meta['TIMEZERO'])
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

        gti_start = t[0] + out_table.meta['TIMEZERO']  # Front of the start-time-bin
        gti_stop = t[1] + out_table.meta['TIMEZERO']  # Back of the end-time-bin

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

    out_table.add_column(Column(data=good_time, name='TIME'))
    out_table.add_column(Column(data=good_chan, name='CHANNEL'))
    out_table.add_column(Column(data=good_pcu, name='PCUID'))

    ##########
    ## Output
    ##########

    assert out_file[-4:].lower() == "fits", "ERROR: Output file must be FITS."
    out_table.write(out_file, overwrite=True)

    # fits_out(out_file, out_table, good_time, good_chan, good_pcu)


################################################################################
if __name__ == "__main__":

    #####################################################
    ## Parsing command line arguments and calling 'main'
    #####################################################

    parser = argparse.ArgumentParser(usage="applygti.py eventlist gtifile "\
            "outfile", description=__doc__)

    parser.add_argument('eventlist', help="The full path of the decoded event "\
            "list file.")

    parser.add_argument('gtifile', help="The full path of the (FITS) GTI file,"\
            " made in HEASoft's 'maketime' script. This program assumes that a"\
            " FITS-format GTI file will have the extension '.gti'.")

    parser.add_argument('outfile', help="Name of the .fits output file, to "\
            "write the GTI'd event list to.")

    args = parser.parse_args()

    main(args.eventlist, args.gtifile, args.outfile)

################################################################################
