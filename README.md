# Multi-Sample Metagenomic Assembly Pipeline

## Description
A comprehensive metagenomic assembly pipeline for co-assembling multiple samples into a single set of contigs. This pipeline performs unbiased assembly of all organisms present (viruses, bacteria, fungi, archaea) from shotgun sequencing data using both MEGAHIT and metaSPAdes assemblers.

## Features
- Co-assembly of multiple related samples
- Dual assembler approach for maximum sensitivity
- Optimized for both modern and degraded/ancient DNA
- Automated redundancy removal
- Assembly statistics calculation
- HPC/SLURM compatible

## Repository Contents
- `environment.yml` - Conda environment specification
- `merge_for_assembly.sh` - Merges all sample FASTQ files
- `run_assembly_server.sh` - Server-optimized assembly pipeline (SLURM)
- `run_megahit.sh` - MEGAHIT assembly script
- `run_metaspades.sh` - metaSPAdes assembly script
- `calculate_stats.py` - Assembly statistics calculator

## Quick Start

### 1. Clone Repository
```bash
git clone <repository-url>
cd <repository-name>
```

### 2. Create Conda Environment
```bash
conda env create -f environment.yml
conda activate multi_sample_metagenomic_assembly
```

### 3. Prepare Data
Place your paired-end FASTQ files in the working directory following the naming pattern:
- `*_R1_*.fq` or `*_R1_*.fastq` for forward reads
- `*_R2_*.fq` or `*_R2_*.fastq` for reverse reads

Then merge all samples:
```bash
./merge_for_assembly.sh
```

### 4. Run Assembly

#### Option A: On HPC/Server (Recommended)
```bash
# Adjust SLURM parameters in the script as needed
sbatch run_assembly_server.sh
```

#### Option B: Local Machine
```bash
# Run MEGAHIT
./run_megahit.sh

# Run metaSPAdes
./run_metaspades.sh
```

## System Requirements

### Minimum Requirements
- **Memory**: 32GB RAM
- **CPUs**: 8 cores
- **Storage**: 50GB free space

### Recommended Requirements
- **Memory**: 128GB RAM
- **CPUs**: 32 cores
- **Storage**: 100GB free space
- **Time**: 12-24 hours (varies with data size)

## Output Files
- `assembly_results/megahit/final.contigs.fa` - MEGAHIT contigs
- `assembly_results/metaspades/contigs.fasta` - metaSPAdes contigs
- `assembly_results/final_contigs_nr.fa` - Non-redundant combined contigs
- `assembly_results/assembly_stats.txt` - Assembly statistics

## Pipeline Parameters

### MEGAHIT
- K-mer range: 21,29,39,59,79,99,119,141
- Preset: meta-sensitive
- Minimum contig length: 500bp

### metaSPAdes
- K-mer range: 21,33,55,77,99,127
- Mode: metagenomic
- Minimum contig length: 500bp

### Redundancy Removal
- CD-HIT-EST similarity threshold: 0.95
- Word size: 10

## Customization
To modify assembly parameters, edit the respective shell scripts:
- Adjust k-mer ranges for your read length
- Modify thread count based on available resources
- Change minimum contig length thresholds
- Add additional preprocessing steps

## Post-Assembly Analysis
Recommended downstream analyses:
1. Taxonomic classification (Kraken2, Centrifuge, DIAMOND)
2. Functional annotation (Prokka, DRAM)
3. Read mapping and coverage calculation (Bowtie2, BBMap)
4. Binning (MetaBAT2, CONCOCT)
5. Quality assessment (CheckM, BUSCO)

## Troubleshooting
- **Memory errors**: Reduce thread count and k-mer range
- **Path issues**: Ensure all paths with spaces are properly quoted
- **Long runtime**: Check log files for bottlenecks
- **Poor assembly**: Consider adjusting k-mer ranges or minimum contig length

## Citation
If you use this pipeline, please cite:
- MEGAHIT: Li, D., et al. (2015). MEGAHIT: an ultra-fast single-node solution for large and complex metagenomics assembly via succinct de Bruijn graph. Bioinformatics, 31(10), 1674-1676.
- metaSPAdes: Nurk, S., et al. (2017). metaSPAdes: a new versatile metagenomic assembler. Genome research, 27(5), 824-834.
- CD-HIT: Fu, L., et al. (2012). CD-HIT: accelerated for clustering the next-generation sequencing data. Bioinformatics, 28(23), 3150-3152.