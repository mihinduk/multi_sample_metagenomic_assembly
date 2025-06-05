#!/bin/bash

# MEGAHIT assembly
# Optimized for metagenomes with mixed read lengths
megahit \
    -1 "merged_R1.fq" \
    -2 "merged_R2.fq" \
    -o "megahit_assembly" \
    --k-list 21,29,39,59,79,99,119,141 \
    --min-contig-len 500 \
    -t 8 \
    --presets meta-sensitive