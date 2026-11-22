#!/bin/bash
#SBATCH --job-name=align_qc
#SBATCH --cpus-per-task=8
#SBATCH --mem=24G
#SBATCH --time=01:00:00
#SBATCH --output=logs/align_qc_%j.out

set -euo pipefail

mkdir -p qc/rseqc qc/deeptools qc/multiqc
BED="ref/gencode.v50.annotation.bed"
PC_BED="ref/gencode.v50.protein_coding.bed"
BAMS="quant/star/SRR1039520_Aligned.sortedByCoord.out.bam quant/star/SRR1039512_Aligned.sortedByCoord.out.bam quant/star/SRR1039517_Aligned.sortedByCoord.out.bam quant/star/SRR1039514_Aligned.sortedByCoord.out.bam"

# 1. Per-sample RSeQC metrics (skips if already generated)
for acc in SRR1039520 SRR1039512 SRR1039517 SRR1039514; do
    BAM="quant/star/${acc}_Aligned.sortedByCoord.out.bam"
    if [ ! -s "qc/rseqc/${acc}.inner_distance.inner_distance_freq.txt" ]; then
        echo "[RSeQC] Processing ${acc}..."
        ~/miniforge3/bin/mamba run -n qc bam_stat.py -i "$BAM" > "qc/rseqc/${acc}.bam_stat.txt"
        ~/miniforge3/bin/mamba run -n qc infer_experiment.py -r "$BED" -i "$BAM" > "qc/rseqc/${acc}.infer_experiment.txt"
        ~/miniforge3/bin/mamba run -n qc read_distribution.py -r "$BED" -i "$BAM" > "qc/rseqc/${acc}.read_distribution.txt"
        ~/miniforge3/bin/mamba run -n qc inner_distance.py -r "$BED" -i "$BAM" -o "qc/rseqc/${acc}.inner_distance"
    else
        echo "[SKIP] ${acc} per-sample RSeQC already complete."
    fi
done

# 2. Gene body coverage across canonical protein-coding transcripts (~19k genes -> finishes in ~2 min)
echo "[RSeQC] Running geneBody_coverage.py..."
~/miniforge3/bin/mamba run -n qc geneBody_coverage.py \
    -r "$PC_BED" \
    -i quant/star/ \
    -o qc/rseqc/all_samples

# 3. deepTools multi-sample correlation & PCA
echo "[deepTools] Running multiBamSummary, plotCorrelation, and plotPCA..."
~/miniforge3/bin/mamba run -n qc multiBamSummary bins \
    --bamfiles $BAMS \
    --labels SRR1039520 SRR1039512 SRR1039517 SRR1039514 \
    -p 8 \
    -o qc/deeptools/results.npz

~/miniforge3/bin/mamba run -n qc plotCorrelation \
    -in qc/deeptools/results.npz \
    --corMethod spearman --skipZeros \
    --whatToPlot heatmap --colorMap RdYlBu_r --plotNumbers \
    -o qc/deeptools/heatmap_SpearmanCorr.png

~/miniforge3/bin/mamba run -n qc plotPCA \
    -in qc/deeptools/results.npz \
    -T "PCA of GSE52778 RNA-seq BAMs" \
    -o qc/deeptools/PCA_readCounts.png

# 4. Aggregate all pipeline QC & quantification reports with MultiQC
echo "[MultiQC] Aggregating reports..."
~/miniforge3/bin/mamba run -n qc multiqc \
    qc/fastp qc/trimmed quant/star quant/counts quant/salmon qc/rseqc \
    -o qc/multiqc --force
