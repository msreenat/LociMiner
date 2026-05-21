# LociMiner
A pipeline to maximise data recovery from next generation sequencing data.
File and script set up for Loci Miner mapping/assembly (LM) and concatenation scripts (CW).
The scripts for this pipeline are currently set up to run as a batch jobs on slurm, a few tweaks to paths and directories should enable them to run locally on personal machines. Based on Legacy Miner. 

**Part one** **- Trimming, mapping and removing soft clip annotations from your reads**

**Requirements** - LM.sh script, settings.sh script, raw data, reference file, adapters file (NEBNext-PE.fa), soft2match.py, SamplesFileNames.txt
**Package requirements** - Trimmomatic, Bowtie2, Samtools

**LM.sh** - script file that will trim and map samples in a loop

**Raw data** - data with file names appended by *_R1.fq.gz and *_R2.fq.gz

**SamplesFileNames.txt** - a text file with all the samples names as a list so that the script will trim and map as a loop

**Reference file** - gene/whole chloroplast sequences of a single species of the family.

**settings.cfg** - file that gives PRM.sh the location of your raw data, reference file, python script, adapter file for trimming and whether or not your samples need to be trimmed.

**soft2match.py** - a python script that converts soft clipped reads in the mapped bam output from bowtie2 into matched/mismatched reads.

Editing the settings.cfg file - this tells your script file LM.sh where your raw data, reference file, and python script are. This is also where you tell the script if the samples need trimming or not.

The bam outputs from soft2match.py have the sample names appended by _nosoft.bam.



**Part two - De novo assembly of the mapped reads**

**Requirements** - Geneious Prime, Velevet or Spades

**Note** - if you are using either Velvet or Spades you will need to identify the optimum kmer value for each loci for each species. Geneious Prime has an inbuilt assembler that seems to automatically assess the best kmer value.

**Geneious Prime** - you can create a workflow (loop) that allows you to batch rename the samples, finds the best contig and calls consensus - output file is in fasta format.

The output files need to end with _loci.fasta - both the name of the file and the name of the sequence inside the file.
Replace loci with the name of the loci



**Part three - Concatenation of assembled genes and combining them with legacy data**

**Requirements** - CW.sh, settings2.cfg
**Package requirements** - MAFFTT, AMAS

**CW.sh** - script file that will concatenate the loci files and the legacy files to output a multifasta for the family
**settings2.cfg** - file that gives CW.sh the location of the assembled loci files in fasta format, the legacy data also in fasta format, a list of the loci, and a direct path to the concatentation package AMAS.

**Legacy data** - previously existing alignments for the family, split into the individual loci with each species and file having the suffix *_loci. The package AMAS can be used to split an alignmnet based on the loci as long as the lengths and locations of these loci are known (partitions).

This command built into a script will allow you to add loci tags to the headers of each species in a fasta file -
"sed '/^>/s/$/_matK/g' Mega_matK.fasta > New_Mega_matK.fas"

The output of CW.sh will be an aligned multifasta that will hold new and old samples. It is worth manually checking the alignment.

DONE.


