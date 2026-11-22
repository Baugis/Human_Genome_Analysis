#!/bin/bash
#SBATCH --job-name=star_counts
#SBATCH --cpus-per-task=8
#SBATCH --mem=48G
#SBATCH --time=04:00:00
#SBATCH --output=logs/star_counts_%j.out

# 1. Align trimmed paired-end reads to GRCh38 with STAR (coordinate-sorted BAM)
for acc in SRR1039520 SRR1039512 SRR1039517 SRR1039514; do
    ~/miniforge3/bin/mamba run -n bioinfo STAR \
        --runThreadN 8 \
        --genomeDir ref/star_index \
        --readFilesIn trimmed/fastq/${acc}_1.trimmed.fastq.gz trimmed/fastq/${acc}_2.trimmed.fastq.gz \
        --readFilesCommand zcat \
        --outFileNamePrefix quant/star/${acc}_ \
        --outSAMtype BAM SortedByCoordinate \
        --quantMode GeneCounts
done

# 2. Index BAM files with samtools
for bam in quant/star/*_Aligned.sortedByCoord.out.bam; do
    ~/miniforge3/bin/mamba run -n bioinfo samtools index -@ 8 "$bam"
done

# 3. Quantify gene-level counts across all 4 BAMs with featureCounts
~/miniforge3/bin/mamba run -n bioinfo featureCounts \
    -T 8 \
    -p --countReadPairs \
    -B -C \
    -t exon \
    -g gene_id \
    -a ref/gencode.v50.primary_assembly.annotation.gtf \
    -o quant/counts/gene_counts.txt \
    quant/star/*_Aligned.sortedByCoord.out.bam
