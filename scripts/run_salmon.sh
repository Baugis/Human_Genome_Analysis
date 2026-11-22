#!/bin/bash
#SBATCH --job-name=salmon_quant
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=01:00:00
#SBATCH --output=logs/salmon_quant_%j.out

# loops through SRA accesions. Checks whether the main output file
# exist and is not empty. (-s) 
# then path to salmon and its subcommand to quantify
# settings:
# -i points to pre-built GENCODE transcriptome index created earlier
# 	 by index_salmon.sh
# -l A = automatic library type detection. IU - unstranded, ISF - stranded forward
# 	 or stranded reverse ISR, so we wouldn't have to do that manually
# -1 = input forward reads
# -2 = input reverse reads
# -p 8 = 8 CPU threads
# -gcBias = Fragment level GC bias correction
# -o = output directory


for acc in SRR1039520 SRR1039512 SRR1039517 SRR1039514; do
    if [ -s "quant/salmon/${acc}/quant.sf" ]; then
        echo "[SKIP] ${acc} already quantified."
        continue
    fi
    ~/miniforge3/bin/mamba run -n bioinfo salmon quant \
        -i ref/salmon_index \
        -l A \
        -1 trimmed/fastq/${acc}_1.trimmed.fastq.gz \
        -2 trimmed/fastq/${acc}_2.trimmed.fastq.gz \
        -p 8 \
        --gcBias \
        -o quant/salmon/${acc}
done
