echo "Welcome to the test Hepatitis C genotyping pipeline"

#Notes down start time
start=$SECONDS

for SAMPLE_ID in $@

#Loop
do
	#Index the aligner with the reference genome
	bwa index -a is HCV1.fasta
	# Align reads 1 of samples to reference genome
	bwa aln HCV1.fasta $SAMPLE_ID.1.fastq >$SAMPLE_ID.1.sai
	# Align reads 2 of samples to reference genome
	bwa aln HCV1.fasta $SAMPLE_ID.2.fastq >$SAMPLE_ID.2.sai
	# Merge and change into SAM format for both samples
	bwa sampe HCV1.fasta $SAMPLE_ID.1.sai $SAMPLE_ID.2.sai $SAMPLE_ID.1.fastq $SAMPLE_ID.2.fastq > $SAMPLE_ID.sam
	# Change the SAM to BAM format for both samples
	samtools view -bt HCV1.fasta $SAMPLE_ID.sam>$SAMPLE_ID.bam
	# Sort the BAM files
	samtools sort $SAMPLE_ID.bam -o $SAMPLE_ID.sorted.bam
	# Create the index file for the BAM files
	samtools index -b  $SAMPLE_ID.sorted.bam

#Create mpileup file and VCF file containing SNPs
samtools mpileup -IEuDSf HCV1.fasta $SAMPLE_ID.sorted.bam | bcftools view -v snps - > $SAMPLE_ID.vcf

#Compress the VCF with tabix and its index
bgzip -c $SAMPLE_ID.vcf > $SAMPLE_ID.vcf.gz
tabix -p vcf $SAMPLE_ID.vcf.gz

# Create a consensus sequence in FASTA format from newly-created VCF and the reference sequence
cat HCV1.fasta | bcftools consensus $SAMPLE_ID.vcf.gz > $SAMPLE_ID-consensus.fa
done

#Produce running time of script
end=$SECONDS
duration=$(( end - start ))
echo "The process took $end seconds to complete"
