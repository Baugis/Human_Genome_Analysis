#!/bin/bash
#SBATCH --job-name=raw_fastqc
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=00:45:00
#SBATCH --output=logs/raw_fastqc_%j.out

# - n bioinfo = path where fastqc is downloaded
# uses 4 threads allowing to run all 4 files on fastqc
# --outdir qc/raw = direct output files in qc/raw
~/miniforge3/bin/mamba run -n bioinfo fastqc -t 4 --outdir qc/raw raw/fastq/*.fastq.gz
