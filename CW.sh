#!/bin/bash
#SBATCH --job-name=CW
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --output=CW.%j.out
#SBATCH --error=CW.%j.err
#SBATCH --partition=medium



# Concatenation of mapped and assembled genes fastas #
#       Madhavi Sreenath and Hannah Wilson           #


#Load settings
. ~/path/to/directory/settings2.cfg
cat ~/path/to/directory/settings2.cfg

#Copy fastas to current directory
cp $data/*.fasta .

#Make a directory for used files
mkdir Processed

#Build multifasta for each loci and move single seq fastas
cat *_loci1.fasta > loci1.fas
cat *_loci2.fasta > loci2.fas
cat *_loci3.fasta > loci3.fas

#Tidy directory
mv *.fasta Processed

#Copy legacy daata from Legacy
cp $legacy/*.fasta .

#Combine the legacy data and newly generated data
cat loci1.fas New_Mega_loci1.fasta > loci1.fasta
cat loci2.fas New_Mega_loci2.fasta > loci2.fasta
cat loci3.fas New_Mega_loci3.fasta > loci3.fasta

#Tidy directory
mv *.fas New_Mega_* Processed

#Use MAFFT to align sequences in each loci specific multifasta
cp ~/path/to/directory/loci .
for file in $(cat loci)
        do
        mafft ${file} > aligned_${file}
done

echo "done"

# remove loci tags from headers so amas can match up samples
sed 's/_loci1//g' aligned_loci1.fasta > clean_aligned_loci1.fas
sed 's/_loci2//g' aligned_loci2.fasta > clean_aligned_loci2.fas
sed 's/_loci3//g' aligned_loci3.fasta > clean_aligned_loci3.fas

#Make working directory for AMAS, move clean alignments to it and move into it
mkdir AMAS
cp clean_aligned_* AMAS/
cd AMAS

#Concatenate gene alignments using AMAS. - output file in fasta format; Note if there is a specific order of genes for concatenation this order has to be put in place of *fas
python $AMAS concat -f fasta -d dna -i *fas -u fasta

cp concatenated.out concat.fasta

echo "concatenated gene alignment written to concatenated.fasta"

#Remove "." from sample names
sed 's/.//g' concat.fasta 

#Delete empty lines
sed '/^$/d' concat.fasta

#Removes line breaks from fasta file
awk '!/^>/ { printf "%s", $0; n = "\n" } /^>/ { print n $0; n = "" } END { printf "%s", n }' concat.fasta > alignment.fasta

#Replace newline with ' ' if line starts with '>' (i.e., merge headers with data into single line separated by space)
sed '/^>/{N; s/\n/ /;}' alignment.fasta

