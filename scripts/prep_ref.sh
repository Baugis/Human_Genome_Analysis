#!/bin/bash
#SBATCH --job-name=prep_ref
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --time=00:20:00
#SBATCH --output=logs/prep_ref_%j.out

# options above:
# 2 cpus for this task &&  using 4gb of ram 
# time - maximum time for process
# redirects stdout and stderr to prep_ref_%j.out  %j = slurm variable
# unique numeric Job id

# decompress the refference genomes -k option - keep the gz files
# by default it deltes the gz files when decompressed
gunzip -k ref/GRCh38.primary_assembly.genome.fa.gz
gunzip -k ref/gencode.v50.primary_assembly.annotation.gtf.gz
gunzip -k ref/gencode.v50.transcripts.fa.gz
