#!/bin/bash
#SBATCH --job-name=measles_metagenome
#SBATCH --time=24:00:00
#SBATCH --mem=128G
#SBATCH --cpus-per-task=32
#SBATCH --output=assembly_%j.log

# Server-optimized metagenomic assembly pipeline
# For 1912 formalin-fixed lung specimen

echo "Starting assembly pipeline at $(date)"

# Activate conda environment
conda activate multi_sample_metagenomic_assembly

# Create output directories
mkdir -p assembly_results/{megahit,metaspades,logs}

# Run MEGAHIT (fast, memory-efficient)
echo "Running MEGAHIT assembly..."
megahit \
    -1 merged_R1.fq \
    -2 merged_R2.fq \
    -o assembly_results/megahit \
    --k-list 21,29,39,59,79,99,119,141 \
    --min-contig-len 500 \
    -t 32 \
    --presets meta-sensitive \
    2>&1 | tee assembly_results/logs/megahit.log

# Run metaSPAdes (more sensitive for low-abundance organisms)
echo "Running metaSPAdes assembly..."
metaspades.py \
    -1 merged_R1.fq \
    -2 merged_R2.fq \
    -o assembly_results/metaspades \
    -k 21,33,55,77,99,127 \
    -t 32 \
    --memory 128 \
    2>&1 | tee assembly_results/logs/metaspades.log

# Combine and filter assemblies
echo "Processing final contigs..."
cat assembly_results/megahit/final.contigs.fa > assembly_results/all_contigs.fa
cat assembly_results/metaspades/contigs.fasta >> assembly_results/all_contigs.fa

# Remove redundancy and filter by length
cd-hit-est \
    -i assembly_results/all_contigs.fa \
    -o assembly_results/final_contigs_nr.fa \
    -c 0.95 \
    -n 10 \
    -T 32 \
    -M 64000

# Generate assembly statistics
python3 calculate_stats.py \
    assembly_results/final_contigs_nr.fa \
    > assembly_results/assembly_stats.txt

echo "Assembly pipeline completed at $(date)"