#!/bin/bash
#SBATCH --job-name=salmon_idx
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=00:30:00
#SBATCH --output=logs/salmon_idx_%j.out

# building transriptome index for salmon a tool used to estimate gene
# and transcript expression levels form RNA-seq reads


# ~/miniforge2/bin... =  path to salmon and runs "index" subcommand 
# settings:
# -t = specifies the input transciptotme FASTA file. Salmon can read fa.gz directly
# -i = specifies the output directory path
#
# --gencode =  crucial flag for GENCODE files. Tells salmon
# to split the header on the first | so it can cleanly extract
# the transcript id, rather than treating the entire long metadata string
# as transcript name
# 
# -p 4 = 4threads
~/miniforge3/bin/mamba run -n bioinfo salmon index \
    -t ref/gencode.v50.transcripts.fa.gz \
    -i ref/salmon_index \
    --gencode \
    -p 4
