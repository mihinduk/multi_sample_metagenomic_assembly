#!/bin/bash

# Run MEGAHIT from home directory to avoid space issues
cd ~/measles_assembly_tmp

megahit \
    -1 merged_R1.fq \
    -2 merged_R2.fq \
    -o megahit_assembly \
    --k-list 21,29,39,59,79,99,119,141 \
    --min-contig-len 500 \
    -t 8 \
    --presets meta-sensitive

# Copy results back
cp -r megahit_assembly "/Users/handley_lab/Handley Lab Dropbox/virome/viral_archaeology/formalin_fixed_measles/lung_only/tmp/"