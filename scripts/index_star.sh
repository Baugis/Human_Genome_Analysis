#!/bin/bash
#SBATCH --job-name=star_idx
#SBATCH --cpus-per-task=8
#SBATCH --mem=56G
#SBATCH --time=02:00:00
#SBATCH --output=logs/star_idx_%j.out

# ~/miniforge3/bin/mamba... = path to STAR program
# - runs on 8 cpu threads
# - runMode genomeGenerate - instructs STAR to build index genome
#	rather than align reads
# - genomeDir = path to output directory
# - genomeFastaFiles = the uncompressed human refference genome 
#	fasta sequence, as it cannot read compressed files
# - sjdbGTFfile = path to ucompressed GENCODE v50 gene anotation file
#   STAR parses this GTF to extract known exon boundaries and build 
# 	splice junction database
# - sjdbOverhang 62 = tailore to direct datasets read length
# - limitGenbomeGenerateRam = Caps STAR's internal RAM usage at 
#	52 milion bytes = 48.8GB
# 

~/miniforge3/bin/mamba run -n bioinfo STAR \
    --runThreadN 8 \
    --runMode genomeGenerate \
    --genomeDir ref/star_index \
    --genomeFastaFiles ref/GRCh38.primary_assembly.genome.fa \
    --sjdbGTFfile ref/gencode.v50.primary_assembly.annotation.gtf \
    --sjdbOverhang 62 \
    --limitGenomeGenerateRAM 52000000000
