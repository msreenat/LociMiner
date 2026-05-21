#!/bin/bash
#SBATCH --job-name=PRM
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --output=PRM.%j.out
#SBATCH --error=PRM.%j.err
#SBATCH --partition=long

#    Plastid Region Miner (PRM) #
#        Madhavi Sreenath       #

#Complete path and set configuration for selected location
	echo -e "\nPlastid Region Miner is running on Gruffalo...\n"

# Load settings from settings.cfg
. ~/path/to/directory/settings.cfg
cat ~/path/to/directory/settings.cfg

#Make and enter a working directory for the job
mkdir ~/path/to/directory/$SLURM_JOBID
cd ~/path/to/directory/$SLURM_JOBID

# Copy files from data repository
cp $data/*fq.gz .
cp $Ref .
cp $data/SamplesFileNames.txt .

#Add LF at the end of last line in SamplesFileNames.txt if missing
sed -i.bak '$a\' SamplesFileNames.txt

#Delete empty lines from SamplesFileNames.txt (if any)
sed -i.bak2 '/^$/d' SamplesFileNames.txt

#Build bowtie index
bowtie2-build $Ref RefIndex

if [[ $trimmed =~ "yes" ]]; then
        echo -e "\nReads trimmed using trimmomatic..."
        numberfiles=$(cat SamplesFileNames.txt | wc -l)
        calculating=0
        for file in $(cat SamplesFileNames.txt) #A loop to process all samples as specified in SamplesFileNames.txt
        do	calculating=$((calculating + 1))
                echo -e "\nProcessing sample $file ($calculating out of $numberfiles)"
                #Trim raw reads
		java -jar /path/to/package/trimmomatic-0.39-1/share/trimmomatic-0.39-1/trimmomatic.jar PE -phred33 ${file}_R1.fq.gz ${file}_R2.fq.gz ${file}_forward_paired.fq.gz ${file}_forward_unpaired.fq.gz ${file}_reverse_paired.fq.gz ${file}_reverse_unpaired.fq.gz ILLUMINACLIP:$adapterfile:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36 >Trimmomatic.log 2>&1
            	#Map raw reads to reference using bowtie2
		bowtie2 --local --score-min G,10,8 -x RefIndex -1 ${file}_forward_paired.fq.gz  -2 ${file}_reverse_paired.fq.gz  -U ${file}_forward_unpaired.fq.gz,${file}_reverse_unpaired.fq.gz -S Trimmed_${file}_to_ref.sam 2>Trimmed_${file}_bowtie_out
                #Identify how many of these reads were mapped
		head Trimmed_${file}_bowtie_out
	        #Check the @s in header
                head Trimmed_${file}_to_ref.sam
		#Remove unmapped reads to reduce size of the file
                samtools view -h -F 4 -b Trimmed_${file}_to_ref.sam > MappedTrimmed_${file}.bam
                #Sort the bam file
		samtools sort MappedTrimmed_${file}.bam > Sorted_${file}.bam
                #Index the bam file
		samtools index Sorted_${file}.bam Sorted_${file}.bai
                echo "Remove soft clip annotations with python..."
                #Change CIGAR string annotations of soft clipped reads to matches/mismatches and recalculate CIGAR string qualifier numbers
                python $Soft Sorted_${file}.bam
		 

        done

else
    	echo -e "\nReads not trimmed..."
        numberfiles=$(cat SamplesFileNames.txt | wc -l) #A loop to process all samples as specified in SamplesFileNames.txt
        calculating=0
        for file in $(cat SamplesFileNames.txt)
        do	calculating=$((calculating + 1))
                echo -e "\nProcessing sample $file ($calculating out of $numberfiles)"
		#Map raw reads to reference using bowtie2
		bowtie2 --local --score-min G,10,8 -x RefIndex -1 ${file}_R1.fq.gz  -2 ${file}_R2.fq.gz  -S Bowtied_${file}.sam 2>Bowtied_${file}_bowtie_out
                #Identify how many of these reads were mapped
		head Bowtied_${file}_bowtie_out
		#Check the @s in header
                head Bowtied_${file}.sam
		#Remove unmapped reads to reduce size of the file
                samtools view -h -F 4 -b Bowtied_${file}.sam > MappedBowtied_${file}.bam
		#Sort the bam file
                samtools sort MappedBowtied_${file}.bam > Sorted_${file}.bam
		#Index the bam file
                samtools index Sorted_${file}.bam Sorted_${file}.bai
                echo "Remove soft clip annotations with python..."
               	#Change CIGAR string annotations of soft clipped reads to matches/mismatches and recalculate CIGAR string qualifier numbers
                python $Soft Sorted_${file}.bam
		
        done
fi 
        
#Remove raw files from working directory
rm *.fq.gz

#Rename headings inside fasta files to include name of the file
for i in *.fasta
	do n="${i%.fasta}"
	sed -i.bak "s/>[^_]\+/>$n/" $i
        sed -i.bak "s/_cns <unknown description>//" $i
done

#Make directory for no soft bam files 
mkdir ~/path/to/directory

#Copy all no soft bam files to another directory
cp *_nosoft.bam ~/path/to/directory

echo "\nMove to Geneious ....n\"

echo "\nPlastid Region Miner for Whole Genome Sequencing part one is complete...n\"
