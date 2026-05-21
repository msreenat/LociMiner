#!/usr/bin/python

'''

This script converts soft clips to matches/mismatches in a bam/sam files.

Flavia Fonseca Pezzini
November 2022

Usage: python soft2match.py mybamfile.bam
it will output a mybamfile_nosoft.bam

'''

import sys 
import pysam
import re

from itertools import groupby
from operator import itemgetter

bamFile = sys.argv[1];

bam = pysam.AlignmentFile(bamFile, 'rb')
outfile = pysam.AlignmentFile(bamFile.split(".bam")[0]+"_nosoft.bam", "wb", template=bam)

def sum_m_values(values):
    summed = []
    it = iter(values)
    paired = zip(it, it)

    for letter, grouped in groupby(paired, itemgetter(1)):
        if letter == "M":
            total = sum(int(number) for number, _ in grouped)
            summed += (total, letter)
        else:
            # add the (number, "D") as separate elements
            for number, letter in grouped:
                summed += (number, letter)
            
    return summed

for read in bam:
    cigar=read.cigarstring
    cigarsoft = cigar.replace('S', 'M')
    sep = re.findall('(\d+|[A-Za-z]+)', cigarsoft)
    nosoft = (sum_m_values(sep))
    read.cigarstring = ''.join(map(str,nosoft))
    outfile.write(read)
   
outfile.close()
bam.close()    

print("Done, enjoy all the matching reads!")
