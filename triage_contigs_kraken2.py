#!/usr/bin/env python3
"""
Triage contigs by kingdom using Kraken2
Output: Separate FASTA files for bacteria, viruses, fungi, archaea, and other
"""

import sys
import os
import subprocess
import argparse
from collections import defaultdict
from Bio import SeqIO

def run_kraken2(fasta_file, db_path, threads=8, confidence=0.1):
    """Run Kraken2 classification."""
    print(f"Running Kraken2 with database: {db_path}")
    print(f"Confidence threshold: {confidence}")
    
    output_file = fasta_file.replace('.fa', '_kraken2.out')
    report_file = fasta_file.replace('.fa', '_kraken2.report')
    
    cmd = [
        'kraken2',
        '--db', db_path,
        '--threads', str(threads),
        '--output', output_file,
        '--report', report_file,
        '--confidence', str(confidence),
        fasta_file
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        print("Kraken2 classification complete")
        return output_file, report_file
    except subprocess.CalledProcessError as e:
        print(f"Error running Kraken2: {e}")
        print(f"stderr: {e.stderr}")
        sys.exit(1)

def parse_kraken2_output(output_file, fasta_file):
    """Parse Kraken2 output to get kingdom assignments."""
    
    # Kingdom mapping based on taxonomic lineage
    kingdom_keywords = {
        'Bacteria': ['Bacteria', 'bacterium'],
        'Viruses': ['Viruses', 'Virus', 'viridae', 'virus', 'phage', 'Phage'],
        'Fungi': ['Fungi', 'fungus', 'mycota'],
        'Archaea': ['Archaea', 'archaeon'],
        'Eukaryota': ['Eukaryota', 'Metazoa', 'Viridiplantae', 'Protista']
    }
    
    contig_kingdoms = {}
    
    print("\nParsing Kraken2 results...")
    with open(output_file, 'r') as f:
        for line in f:
            parts = line.strip().split('\t')
            if len(parts) < 3:
                continue
                
            status = parts[0]
            contig_id = parts[1]
            taxonomy = parts[2] if len(parts) > 2 else ""
            
            if status == 'U':  # Unclassified
                contig_kingdoms[contig_id] = 'Unclassified'
            else:
                # Determine kingdom from taxonomy string
                kingdom = 'Other'
                for k, keywords in kingdom_keywords.items():
                    if any(kw in taxonomy for kw in keywords):
                        kingdom = k
                        break
                contig_kingdoms[contig_id] = kingdom
    
    return contig_kingdoms

def write_kingdom_fastas(fasta_file, contig_kingdoms, output_dir):
    """Write separate FASTA files for each kingdom."""
    
    # Create output directory
    os.makedirs(output_dir, exist_ok=True)
    
    # Open output file handles
    kingdoms = ['Bacteria', 'Viruses', 'Fungi', 'Archaea', 'Eukaryota', 'Other', 'Unclassified']
    output_handles = {}
    for kingdom in kingdoms:
        output_file = os.path.join(output_dir, f"{kingdom.lower()}_contigs.fa")
        output_handles[kingdom] = open(output_file, 'w')
    
    # Statistics
    stats = defaultdict(lambda: {'count': 0, 'total_bp': 0, 'lengths': []})
    
    # Process contigs
    print("\nWriting kingdom-specific FASTA files...")
    for record in SeqIO.parse(fasta_file, "fasta"):
        kingdom = contig_kingdoms.get(record.id, 'Unclassified')
        
        # Write to appropriate file
        SeqIO.write(record, output_handles[kingdom], "fasta")
        
        # Update statistics
        seq_len = len(record.seq)
        stats[kingdom]['count'] += 1
        stats[kingdom]['total_bp'] += seq_len
        stats[kingdom]['lengths'].append(seq_len)
    
    # Close all file handles
    for handle in output_handles.values():
        handle.close()
    
    return stats, output_dir

def print_summary(stats, output_dir):
    """Print summary statistics."""
    
    print("\n" + "="*80)
    print("KINGDOM-LEVEL TRIAGE SUMMARY")
    print("="*80)
    print(f"{'Kingdom':<15} {'Contigs':>10} {'Total BP':>15} {'Avg Length':>12} {'Max Length':>12}")
    print("-"*80)
    
    total_contigs = 0
    total_bp = 0
    
    kingdoms_order = ['Bacteria', 'Viruses', 'Fungi', 'Archaea', 'Eukaryota', 'Other', 'Unclassified']
    
    for kingdom in kingdoms_order:
        if kingdom in stats and stats[kingdom]['count'] > 0:
            count = stats[kingdom]['count']
            bp = stats[kingdom]['total_bp']
            lengths = stats[kingdom]['lengths']
            avg_len = bp / count
            max_len = max(lengths)
            
            print(f"{kingdom:<15} {count:>10,} {bp:>15,} {avg_len:>12,.0f} {max_len:>12,}")
            total_contigs += count
            total_bp += bp
    
    print("-"*80)
    print(f"{'TOTAL':<15} {total_contigs:>10,} {total_bp:>15,}")
    print("="*80)
    
    # Output file locations
    print(f"\nOutput files saved in: {output_dir}/")
    for kingdom in kingdoms_order:
        if kingdom in stats and stats[kingdom]['count'] > 0:
            print(f"  {kingdom.lower()}_contigs.fa ({stats[kingdom]['count']:,} contigs)")
    
    # Top classifications for viruses (if any)
    if 'Viruses' in stats and stats['Viruses']['count'] > 0:
        print(f"\nViral contigs identified: {stats['Viruses']['count']:,}")
        print("  Run with --keep-intermediates to see detailed classifications")

def main():
    parser = argparse.ArgumentParser(
        description='Triage metagenomic contigs by kingdom using Kraken2',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Example usage:
  # Basic usage with MiniKraken2 database
  python triage_contigs_kraken2.py contigs.fa --db kraken2_db

  # With custom confidence threshold
  python triage_contigs_kraken2.py contigs.fa --db kraken2_db --confidence 0.05

  # Keep intermediate files for inspection
  python triage_contigs_kraken2.py contigs.fa --db kraken2_db --keep-intermediates
        """
    )
    
    parser.add_argument('fasta_file', help='Input FASTA file with contigs')
    parser.add_argument('--db', required=True, help='Path to Kraken2 database')
    parser.add_argument('--output-dir', default='kingdom_triage', 
                        help='Output directory (default: kingdom_triage)')
    parser.add_argument('--threads', type=int, default=8, 
                        help='Number of threads (default: 8)')
    parser.add_argument('--confidence', type=float, default=0.1,
                        help='Kraken2 confidence threshold (default: 0.1)')
    parser.add_argument('--keep-intermediates', action='store_true',
                        help='Keep Kraken2 output files')
    
    args = parser.parse_args()
    
    # Check inputs
    if not os.path.exists(args.fasta_file):
        print(f"Error: Input file {args.fasta_file} not found")
        sys.exit(1)
    
    if not os.path.exists(args.db):
        print(f"Error: Kraken2 database {args.db} not found")
        print("Run setup_kraken2_db.sh to download a database")
        sys.exit(1)
    
    # Run Kraken2
    kraken_out, kraken_report = run_kraken2(
        args.fasta_file, args.db, args.threads, args.confidence
    )
    
    # Parse results
    contig_kingdoms = parse_kraken2_output(kraken_out, args.fasta_file)
    
    # Write kingdom-specific FASTAs
    stats, output_dir = write_kingdom_fastas(
        args.fasta_file, contig_kingdoms, args.output_dir
    )
    
    # Print summary
    print_summary(stats, output_dir)
    
    # Clean up intermediate files
    if not args.keep_intermediates:
        os.remove(kraken_out)
        os.remove(kraken_report)
        print("\nIntermediate files removed. Use --keep-intermediates to retain them.")
    else:
        print(f"\nKraken2 output: {kraken_out}")
        print(f"Kraken2 report: {kraken_report}")

if __name__ == "__main__":
    main()