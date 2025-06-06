#!/bin/bash

# Setup Kraken2 database for kingdom-level classification
# Options: MiniKraken2 (8GB) or Standard (50GB+)

echo "Kraken2 Database Setup"
echo "====================="

# Default to MiniKraken2 for quick triage
DB_TYPE="${1:-minikraken}"
DB_DIR="${2:-kraken2_db}"

mkdir -p "$DB_DIR"

if [ "$DB_TYPE" == "minikraken" ]; then
    echo "Downloading MiniKraken2 database (8GB)..."
    echo "This is sufficient for kingdom-level classification"
    
    cd "$DB_DIR"
    wget -c https://genome-idx.s3.amazonaws.com/kraken/k2_mini_20230605.tar.gz
    echo "Extracting database..."
    tar -xzf k2_mini_20230605.tar.gz
    rm k2_mini_20230605.tar.gz
    cd ..
    
    echo "MiniKraken2 database ready in: $DB_DIR"
    
elif [ "$DB_TYPE" == "viral" ]; then
    echo "Downloading Kraken2 Viral database (1GB)..."
    echo "This contains viral genomes only"
    
    cd "$DB_DIR"
    wget -c https://genome-idx.s3.amazonaws.com/kraken/k2_viral_20230605.tar.gz
    echo "Extracting database..."
    tar -xzf k2_viral_20230605.tar.gz
    rm k2_viral_20230605.tar.gz
    cd ..
    
    echo "Kraken2 Viral database ready in: $DB_DIR"
    
elif [ "$DB_TYPE" == "standard" ]; then
    echo "Downloading Standard Kraken2 database (50GB+)..."
    echo "This will take significant time and disk space"
    
    cd "$DB_DIR"
    kraken2-build --standard --db .
    cd ..
    
    echo "Standard Kraken2 database ready in: $DB_DIR"
    
else
    echo "Usage: $0 [minikraken|viral|standard] [db_directory]"
    echo "  minikraken: 8GB database, good for kingdom-level (default)"
    echo "  viral: 1GB database, viral genomes only"
    echo "  standard: 50GB+ database, comprehensive"
    exit 1
fi

echo ""
echo "To use this database, run:"
echo "  python triage_contigs_kraken2.py <contigs.fa> --db $DB_DIR"