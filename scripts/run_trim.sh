#!/bin/bash
#SBATCH --job-name=fastp_trim
#SBATCH --cpus-per-task=4
#SBATCH --mem=12G
#SBATCH --time=01:30:00
#SBATCH --output=logs/fastp_trim_%j.out


# ~/miniforge3/bin/mamba = path to fastp
#
# -i and -I = inputs forward and reverse reads
#
# -o and -O = outputs of forward and reverse reads
#
# --detect_adapter_for_pe = by default, fastp detects adapters automaticaly
# for single end data, not paired end data. So we wouln't need to write the adapter
# manually
#
# --html and --json = outputs coressponding reads in json and html formats in 
# provided path 
# 
# after for cycle is finished, runs quality control on trimmed reads

for acc in SRR1039520 SRR1039512 SRR1039517 SRR1039514; do
    ~/miniforge3/bin/mamba run -n bioinfo fastp \
        -i raw/fastq/${acc}_1.fastq.gz \
        -I raw/fastq/${acc}_2.fastq.gz \
        -o trimmed/fastq/${acc}_1.trimmed.fastq.gz \
        -O trimmed/fastq/${acc}_2.trimmed.fastq.gz \
        --detect_adapter_for_pe \
        --thread 4 \
        --html qc/fastp/${acc}_fastp.html \
        --json qc/fastp/${acc}_fastp.json
done

~/miniforge3/bin/mamba run -n bioinfo fastqc -t 4 --outdir qc/trimmed trimmed/fastq/*.fastq.gz
