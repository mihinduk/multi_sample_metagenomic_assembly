#!/usr/bin/env python3
"""Calculate assembly statistics for metagenomic contigs."""

import sys
from Bio import SeqIO
import numpy as np

def calculate_n50(lengths):
    """Calculate N50 metric."""
    sorted_lengths = sorted(lengths, reverse=True)
    total = sum(sorted_lengths)
    cumsum = 0
    for length in sorted_lengths:
        cumsum += length
        if cumsum >= total / 2:
            return length
    return 0

def main(fasta_file):
    lengths = []
    total_bases = 0
    
    for record in SeqIO.parse(fasta_file, "fasta"):
        length = len(record.seq)
        lengths.append(length)
        total_bases += length
    
    if not lengths:
        print("No contigs found!")
        return
    
    lengths_array = np.array(lengths)
    
    print(f"Assembly Statistics for {fasta_file}")
    print("-" * 50)
    print(f"Total contigs: {len(lengths):,}")
    print(f"Total bases: {total_bases:,}")
    print(f"Longest contig: {max(lengths):,} bp")
    print(f"Shortest contig: {min(lengths):,} bp")
    print(f"Mean contig length: {int(np.mean(lengths_array)):,} bp")
    print(f"Median contig length: {int(np.median(lengths_array)):,} bp")
    print(f"N50: {calculate_n50(lengths):,} bp")
    
    # Length distribution
    print("\nLength distribution:")
    for threshold in [500, 1000, 5000, 10000, 50000]:
        count = sum(1 for l in lengths if l >= threshold)
        print(f"  >= {threshold:,} bp: {count:,} contigs")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python calculate_stats.py <fasta_file>")
        sys.exit(1)
    main(sys.argv[1])