#!/usr/bin/python
#
# pcacorr.py
#
# Produce a new PHA file with the correction
# from the Crab data.
#
# http://hea-www.cfa.harvard.edu/~javier/pcacorr/
# http://hea-www.cfa.harvard.edu/~javier/pcacorr/corrections/pcacorr.py
#
#
# Requires: numpy, pyfits
#
import sys 
import glob
import re
from numpy import *
import pyfits
from optparse import OptionParser
import os,os.path
import time
from datetime import datetime
#
# ------------------------------------------------------------------------------
# regrid data set
#
# mesh - original mesh
# dat - original data
# pmesh - new mesh
#
# return - array of data on new mesh
def regrid_dat(mesh,dat,pmesh):
  out=[]
  for ix in range(len(pmesh)):
    x=pmesh[ix]

    if x < mesh[0]:            # interpolate to the left
      out.append(interpolate(x,mesh[0],dat[0],mesh[1],dat[1]))
    elif x > mesh[-1]:         # interpolate to the right
      out.append(interpolate(x,mesh[-2],dat[-2],mesh[-1],dat[-1]))
    else:                      # normal interpolation
      ixp=0
      while mesh[ixp] < x: ixp+=1
      out.append(interpolate(x,mesh[ixp-1],dat[ixp-1],mesh[ixp],dat[ixp]))

  return out
# ------------------------------------------------------------------------------
#
# perform linear interpolation (or extrapolation)
#
# x0 - where to interpolate
# x1 - 1st x point
# y1 - 1st y point
# x2 - 2nd x point
# y2 - 2nd y point
#
# return - interpolated y point
def interpolate(x0,x1,y1,x2,y2):
  if (x1 == x2):
    print "cannot interpolate given indentical x1 and x2"
    raise
  slope=(y2-y1)/(x2-x1)
  return y1+slope*(x0-x1)
#
# ------------------------------------------------------------------------------
#
# Read a file and return a list of lines
#
# infile - File name
# lines  - List of lines in the file
#
def read_lines(infile):
  lines=[]
  fin=open(infile,'r')
  while 1:
    tline=fin.readline()
    if tline == '': break                # Reaches EOF
    if tline.strip() == '': continue     # Avoid empty lines
    lines.append(tline.strip().split())
  fin.close
  return lines
#
# ------------------------------------------------------------------------------
#
# MAIN PROGRAM
#
#
#
version='0.1d'
date='- Tue Sep  2 10:28:58 CEST 2014 -'
author='Javier Garcia <javier@head.cfa.harvard.edu>'
#
ul=[]
ul.append("usage: %prog [options] PREFIX")
ul.append("")
ul.append("Produce a new PHA flie using the correction factors derived from")
ul.append("the analysis to the Crab (see Garcia et al 2014; ApJ, 794, 73G)). A new PHA")
ul.append("file is generated. The response corresponding to the observation")
ul.append("is required. The response file name is obtained from the RESPFILE")
ul.append("key or it must be supplied. The correction file is also required.")
ul.append("PREFIX can be a single PHA file or a group (e.g. *.pha). Please")
ul.append("check the gain epoch of your observation!")
ul.append("")
ul.append("*** Epoch 3 (MJD): 50188-51259")
ul.append("*** Epochs 4 & 5 (MJD): > 51259")
usage=""
for u in ul: usage+=u+'\n'

parser=OptionParser(usage=usage)
parser.add_option("-v","--version",action="store_true",dest="version",default=False,help="show version number")
parser.add_option("-r","--response",dest="respfile",default="",help="specify response file")
parser.add_option("-p","--pcu",dest="pcu",default="2",help="specify which PCU (0-4, default 2)")
parser.add_option("-l","--layer",dest="layer",default="a",help="specify if observation comes from the first layer (\"1\") or all (\"a\", default)")
parser.add_option("-e","--epoch",dest="epoch",default="45",help="specify if observation was taken during gain epoch 3 only (\"3o\"), or during epochs 4 or 5 (\"45\", default)")
parser.add_option("-c","--correction",dest="corfile",default="",help="specify correction file (default corr_pcu2_e45_la.out). Notice that this option overrides -p, -l, and -e options")
parser.add_option("-o","--output",dest="outfile",default="",help="specify alternative output file")
parser.add_option("-b","--background",action="store_true",dest="back",default=False,help="Use associated background file. In this case the corrected file will contain (C-B)/x + B, where C are the cts of the original spectrum, B are the cts of the background, and x is the correction factor. Be aware that the BACKFILE key must be defined in the spectrum file with the correct background filename")

(options,args)=parser.parse_args()

if options.version:
  print 'phacorr.py version:',version,date
  print 'Author:',author
  sys.exit()

if len(args) == 0:
  parser.print_help()
  sys.exit(0)

# Check input options
pcu=options.pcu
layer=options.layer
epoch=options.epoch
corfile=options.corfile

if pcu != "0" and pcu != "1" and pcu != "2" and pcu != "3" and pcu != "4":
  print 'Error: allowed values for -p option are 0, 1, 2, 3, or 4'
  print 'Aborting...'
  sys.exit()

if layer != "1" and layer != "a":
  print 'Error: allowed values for -l option are \"1\" or \"a\"'
  print 'Aborting...'
  sys.exit()

if epoch != "3o" and epoch != "45":
  print 'Error: allowed values for -e option are \"3o\" or \"45\"'
  print 'Aborting...'
  sys.exit()

if corfile == "":
  corfile='corr_pcu'+pcu+'_e'+epoch+'_l'+layer+'.out'
respfile=options.respfile
outfile=options.outfile

# Get current universal date and time 
currtime=str(datetime.utcnow())

#-----
for specfile in args:
  # Check if specfile exist
  if not os.path.isfile(specfile):
    print 'Error: spectrum file',specfile,'does not exist!'
    print 'Aborting...'
    sys.exit()

  else:

    # If outfile is not defined (or multiple files), use the default
    if outfile == "" or int(len(args)) > 1:
      outfile=specfile.split('.pha')[0]+'-corr.pha'

    # Read the correction file
    if not os.path.isfile(corfile):
      print 'Error: correction file',corfile,'does not exist!'
      print 'Aborting...'
      sys.exit()
    corlin=read_lines(corfile)
    
    # Read spectrum file
    hdulist = pyfits.open(specfile)
    header = hdulist[0].header      # reads header
    specdata=hdulist[1].data        # reads data
    
    # Get response file name if not supplied (or multiple files)
    if respfile == "" or int(len(args)):
      respfile=hdulist[1].header['respfile']
    if not os.path.isfile(respfile):
      print 'Error: response file',specfile,'does not exist!'
      print 'Aborting...'
      sys.exit()

    #Background
    backcts=[]
    if options.back:
      backfile=hdulist[1].header['backfile']
      # Read background file
      hdulistback = pyfits.open(backfile)
      backdata=hdulistback[1].data
      for cts in backdata.field('counts'):
        backcts.append(cts)
    else:
      backcts=[0]*len(specdata.field('counts'))
    
    # Read response file
    resplin=pyfits.getdata(respfile,2)
    #resplin=pyfits.getdata(respfile,1)  # Needs to read extension EBOUNDS!!!
    
    # Find the correction factor in the energy grid of the observation
    oldmesh=[]  # Energy in the correction curve
    olddata=[]  # Correction factors
    newmesh=[]  # Energy in the observation
    newdata=[]  # New correction factor
    B=array(corlin)
    oldmesh=map(float,B[:,0].tolist())     # Energy
    olddata=map(float,B[:,1].tolist())     # Correction factors
    
    # Get the energies from response
    for chan in resplin:
      newmesh.append(float(chan[2]+chan[1])/2.)

    # Map to the reference grid
    newdata=regrid_dat(oldmesh,olddata,newmesh)
    
    # First check we have the same number of channels
    if len(newdata) != len(specdata.field('counts')):
      print 'Error: obervation and correction files have different number of channels!'
      print 'Correction:',len(newdata)
      print 'Observation:',len(specdata.field('counts'))
      print 'Aborting...'
      sys.exit()
    
    # Apply the correction factors to the observation
    for i in range(len(specdata.field('counts'))):
      #specdata.field('counts')[i]=specdata.field('counts')[i]/newdata[i]
      #specdata.field('stat_err')[i]=specdata.field('stat_err')[i]/newdata[i]
      specdata.field('counts')[i]=(specdata.field('counts')[i]-backcts[i])/newdata[i]+backcts[i]
      specdata.field('stat_err')[i]=specdata.field('stat_err')[i]/newdata[i] # Check what to do with the errors when background true
    
    # Write corrected spectrum file
    if os.path.isfile(outfile):
      print 'Error: output file ',outfile,' already exist!'
      print 'Aborting...'
      sys.exit()
    else:
      if options.back:
        print 'Corrected spectra written in: ',outfile,'\n   with background:',backfile
      else:
        print 'Corrected spectra written in: ',outfile
      # Include HISTORY comments
      header['HISTORY'] = 'Original file corrected by phacorr.py version '+version
      header['HISTORY'] = 'Creation date: '+currtime+' UTC'
      header['HISTORY'] = 'Correction file '+corfile
      hdulist.writeto(outfile)
sys.exit()
# ------------------------------------------------------------------------------
