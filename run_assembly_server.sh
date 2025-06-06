#!/bin/bash
#SBATCH --job-name=measles_metagenome
#SBATCH --time=24:00:00
#SBATCH --mem=128G
#SBATCH --cpus-per-task=32
#SBATCH --output=assembly_%j.log

# Server-optimized metagenomic assembly pipeline

# Get the directory where this script is located
# For SLURM jobs, we need to find the actual script location, not the temp copy
if [[ -n "${SLURM_JOB_ID}" ]]; then
    # In SLURM, find the script in the submission directory
    SCRIPT_DIR="$(dirname "$(scontrol show job ${SLURM_JOB_ID} | grep -oP 'Command=\K[^ ]+' | head -1)")"
    # If that fails, try to find it relative to working directory
    if [[ ! -f "$SCRIPT_DIR/calculate_stats.py" ]]; then
        if [[ -f "multi_sample_metagenomic_assembly/calculate_stats.py" ]]; then
            SCRIPT_DIR="multi_sample_metagenomic_assembly"
        elif [[ -f "./calculate_stats.py" ]]; then
            SCRIPT_DIR="."
        else
            echo "ERROR: Cannot find calculate_stats.py"
            echo "Please ensure the script is run from the correct directory"
            exit 1
        fi
    fi
else
    # Not in SLURM, use normal method
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
fi

echo "Starting assembly pipeline at $(date)"
echo "Script directory: $SCRIPT_DIR"
echo "Working directory: $(pwd)"

# Activate conda environment
# Source conda.sh for batch jobs
if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
    source "$HOME/miniconda3/etc/profile.d/conda.sh"
elif [ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]; then
    source "$HOME/anaconda3/etc/profile.d/conda.sh"
elif [ -f "/opt/conda/etc/profile.d/conda.sh" ]; then
    source "/opt/conda/etc/profile.d/conda.sh"
else
    echo "ERROR: Could not find conda.sh. Please check your conda installation path."
    echo "You may need to modify this script with your conda location."
    exit 1
fi

conda activate multi_sample_metagenomic_assembly || {
    echo "ERROR: Could not activate multi_sample_metagenomic_assembly environment"
    echo "Please ensure the environment is created with:"
    echo "  conda env create -f $SCRIPT_DIR/environment.yml"
    exit 1
}

# Create output directories (but not the assembler directories - they create their own)
mkdir -p assembly_results/logs

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

# Remove redundancy and filter by length (if cd-hit-est is available)
if command -v cd-hit-est &> /dev/null; then
    echo "Running cd-hit-est to remove redundancy..."
    cd-hit-est \
        -i assembly_results/all_contigs.fa \
        -o assembly_results/final_contigs_nr.fa \
        -c 0.95 \
        -n 10 \
        -T 32 \
        -M 64000
    FINAL_CONTIGS="assembly_results/final_contigs_nr.fa"
else
    echo "cd-hit-est not found, skipping redundancy removal step"
    FINAL_CONTIGS="assembly_results/all_contigs.fa"
fi

# Generate assembly statistics
python3 "$SCRIPT_DIR/calculate_stats.py" \
    "$FINAL_CONTIGS" \
    > assembly_results/assembly_stats.txt

# Kingdom-level triage with Kraken2 (if database exists)
if [ -d "kraken2_db" ] || [ -d "$SCRIPT_DIR/kraken2_db" ]; then
    echo "Running kingdom-level triage with Kraken2..."
    
    # Find database location
    if [ -d "kraken2_db" ]; then
        KRAKEN_DB="kraken2_db"
    else
        KRAKEN_DB="$SCRIPT_DIR/kraken2_db"
    fi
    
    python3 "$SCRIPT_DIR/triage_contigs_kraken2.py" \
        "$FINAL_CONTIGS" \
        --db "$KRAKEN_DB" \
        --output-dir assembly_results/kingdom_triage \
        --threads 32 \
        2>&1 | tee assembly_results/logs/kraken2_triage.log
else
    echo "Kraken2 database not found. Skipping kingdom-level triage."
    echo "To enable triage, run: bash $SCRIPT_DIR/setup_kraken2_db.sh"
fi

echo "Assembly pipeline completed at $(date)"
echo "Final contigs saved to: $FINAL_CONTIGS"