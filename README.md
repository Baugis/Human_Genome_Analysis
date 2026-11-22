Reproducible Snakemake workflow for paired-end human RNA-seq analysis (`GRCh38` / GENCODE v50) on a SLURM HPC cluster. The pipeline performs read QC, adapter trimming, alignment-free quantification (`Salmon`), splice-aware alignment and gene quantification (`STAR` + `featureCounts`), alignment QC (`RSeQC` + `deepTools`), and aggregated reporting (`MultiQC`).

## Repository Structure
- `Snakefile` — Automated Snakemake workflow covering preprocessing, quantification, alignment QC, and MultiQC reporting.
- `config.yaml` — Sample accessions (`SRR1039520`, `SRR1039512`, `SRR1039517`, `SRR1039514`), reference paths, and compute parameters.
- `envs/` — Conda environment definitions (`bioinfo.yaml`, `qc.yaml`).
- `scripts/` — Standalone SLURM bash scripts for data/reference preparation and modular cluster execution.
- `.gitignore` — Excludes raw FASTQ files, BAM/SAM alignments, reference indices, logs, and Conda environments.

## Prerequisites
- `mamba` / `conda` (Miniforge3)
- `snakemake` (installed in a dedicated `snakemake` environment)

## How to Run the Workflow

### 1. Prepare Data and Reference Files (One-Time Setup)
Download the SRA datasets and GENCODE v50 / GRCh38 reference genome, transcriptome, and annotation:
```bash
sbatch scripts/download_sra.sh
sbatch scripts/download_ref.sh
sbatch scripts/prep_ref.sh
