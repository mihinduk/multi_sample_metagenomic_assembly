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
git clone https://github.com/mihinduk/multi_sample_metagenomic_assembly.git
cd multi_sample_metagenomic_assembly
```

### 2. Set Up Environment

#### Option A: Full Installation (Recommended)
```bash
# Create conda environment with all dependencies
conda env create -f environment.yml
conda activate multi_sample_metagenomic_assembly

# Verify installation
which megahit
which metaspades.py
python -c "import Bio; print('Biopython installed')"
```

#### Option B: Minimal Installation
```bash
# Create environment with core tools only
conda create -n multi_sample_metagenomic_assembly -c bioconda python=3.9 megahit spades cd-hit biopython -y
conda activate multi_sample_metagenomic_assembly
```

### 3. Prepare Your Data

#### If running from the repository directory:
```bash
# Copy or link your FASTQ files into the repository
cp /path/to/your/*_R1_*.fq .
cp /path/to/your/*_R2_*.fq .

# Merge all samples
./merge_for_assembly.sh
```

#### If running from a directory containing your FASTQ files:
```bash
# Clone repository as subdirectory
git clone https://github.com/mihinduk/multi_sample_metagenomic_assembly.git

# Merge samples
./multi_sample_metagenomic_assembly/merge_for_assembly.sh
```

### 4. Run Assembly

#### Option A: On HPC with SLURM (Recommended)
```bash
# From directory containing FASTQ files
sbatch multi_sample_metagenomic_assembly/run_assembly_server.sh

# Monitor progress
squeue -u $USER
tail -f assembly_*.log
```

#### Option B: On HPC without SLURM
```bash
# Run in background with nohup
nohup bash multi_sample_metagenomic_assembly/run_assembly_server.sh > assembly.log 2>&1 &
```

#### Option C: Local Machine
```bash
# Activate environment first
conda activate multi_sample_metagenomic_assembly

# Run assemblers
./run_megahit.sh
./run_metaspades.sh

# Combine and deduplicate
cat assembly_results/megahit/final.contigs.fa assembly_results/metaspades/contigs.fasta > assembly_results/all_contigs.fa
cd-hit-est -i assembly_results/all_contigs.fa -o assembly_results/final_contigs_nr.fa -c 0.95 -n 10 -T 8 -M 32000

# Calculate statistics
python calculate_stats.py assembly_results/final_contigs_nr.fa
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

### Common Issues

**"megahit: command not found"**
- Ensure conda environment is activated: `conda activate multi_sample_metagenomic_assembly`
- Verify installation: `which megahit`

**"ModuleNotFoundError: No module named 'Bio'"**
- Install biopython: `conda install -c conda-forge biopython`

**"Output directory already exists"**
- Remove previous results: `rm -rf assembly_results/`

**SLURM: "conda: command not found"**
- The script automatically sources conda, but if it fails, add to your `~/.bashrc`:
  ```bash
  export PATH="$HOME/miniconda3/bin:$PATH"
  ```

**Memory errors**
- Reduce threads: Change `-t 32` to `-t 16` or lower
- Reduce memory: Change `--memory 128` to `--memory 64`
- Use fewer k-mers: Change k-mer list to `21,33,55,77,99`

**Path issues with spaces**
- Run from a directory without spaces in the path
- Or ensure all paths are properly quoted in scripts

**Poor assembly quality**
- Check input read quality with FastQC
- Adjust k-mer ranges based on read length
- Increase minimum contig length to reduce fragmentation

## Citation
If you use this pipeline, please cite:
- MEGAHIT: Li, D., et al. (2015). MEGAHIT: an ultra-fast single-node solution for large and complex metagenomics assembly via succinct de Bruijn graph. Bioinformatics, 31(10), 1674-1676.
- metaSPAdes: Nurk, S., et al. (2017). metaSPAdes: a new versatile metagenomic assembler. Genome research, 27(5), 824-834.
- CD-HIT: Fu, L., et al. (2012). CD-HIT: accelerated for clustering the next-generation sequencing data. Bioinformatics, 28(23), 3150-3152.