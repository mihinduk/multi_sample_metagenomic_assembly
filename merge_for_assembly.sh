#!/bin/bash

# Merge all R1 reads
cat *_R1_nonhuman.fastq.paired.fq > merged_R1.fq

# Merge all R2 reads  
cat *_R2_nonhuman.fastq.paired.fq > merged_R2.fq

echo "Merged files created:"
echo "merged_R1.fq: $(grep -c '^@' merged_R1.fq) reads"
echo "merged_R2.fq: $(grep -c '^@' merged_R2.fq) reads"