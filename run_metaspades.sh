#!/bin/bash

# metaSPAdes assembly
# Better for low-abundance organisms
metaspades.py \
    -1 "merged_R1.fq" \
    -2 "merged_R2.fq" \
    -o "metaspades_assembly" \
    -k 21,33,55,77,99,127 \
    -t 8 \
    --memory 32