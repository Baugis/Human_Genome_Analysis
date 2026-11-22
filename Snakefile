configfile: "config.yaml"

SAMPLES = config["samples"]

rule all:
    input:
        "qc/multiqc/multiqc_report.html",
        "qc/deeptools/heatmap_SpearmanCorr.png",
        "qc/deeptools/PCA_readCounts.png",
        "qc/rseqc/all_samples.geneBodyCoverage.txt",
        expand("quant/salmon/{sample}/quant.sf", sample=SAMPLES),
        "quant/counts/gene_counts.txt"

rule fastqc_raw:
    input:
        r1 = "raw/fastq/{sample}_1.fastq.gz",
        r2 = "raw/fastq/{sample}_2.fastq.gz"
    output:
        html1 = "qc/raw/{sample}_1_fastqc.html",
        html2 = "qc/raw/{sample}_2_fastqc.html"
    log:
        "logs/fastqc_raw_{sample}.log"
    conda:
        "envs/bioinfo.yaml"
    threads: 4
    resources:
        mem_mb = 4000
    shell:
        "fastqc -t {threads} --outdir qc/raw {input.r1} {input.r2} > {log} 2>&1"

rule fastp_trim:
    input:
        r1 = "raw/fastq/{sample}_1.fastq.gz",
        r2 = "raw/fastq/{sample}_2.fastq.gz"
    output:
        r1 = "trimmed/fastq/{sample}_1.trimmed.fastq.gz",
        r2 = "trimmed/fastq/{sample}_2.trimmed.fastq.gz",
        html = "qc/fastp/{sample}_fastp.html",
        json = "qc/fastp/{sample}_fastp.json"
    log:
        "logs/fastp_{sample}.log"
    conda:
        "envs/bioinfo.yaml"
    threads: 4
    resources:
        mem_mb = 8000
    shell:
        """
        fastp -i {input.r1} -I {input.r2} \
            -o {output.r1} -O {output.r2} \
            --detect_adapter_for_pe --thread {threads} \
            --html {output.html} --json {output.json} > {log} 2>&1
        """

rule fastqc_trimmed:
    input:
        r1 = "trimmed/fastq/{sample}_1.trimmed.fastq.gz",
        r2 = "trimmed/fastq/{sample}_2.trimmed.fastq.gz"
    output:
        html1 = "qc/trimmed/{sample}_1.trimmed_fastqc.html",
        html2 = "qc/trimmed/{sample}_2.trimmed_fastqc.html"
    log:
        "logs/fastqc_trimmed_{sample}.log"
    conda:
        "envs/bioinfo.yaml"
    threads: 4
    resources:
        mem_mb = 4000
    shell:
        "fastqc -t {threads} --outdir qc/trimmed {input.r1} {input.r2} > {log} 2>&1"

rule salmon_index:
    input:
        config["transcripts_fa"]
    output:
        directory("ref/salmon_index")
    log:
        "logs/salmon_index.log"
    conda:
        "envs/bioinfo.yaml"
    threads: 4
    resources:
        mem_mb = 16000
    shell:
        "salmon index -t {input} -i {output} --gencode -p {threads} > {log} 2>&1"

rule salmon_quant:
    input:
        idx = "ref/salmon_index",
        r1 = "trimmed/fastq/{sample}_1.trimmed.fastq.gz",
        r2 = "trimmed/fastq/{sample}_2.trimmed.fastq.gz"
    output:
        "quant/salmon/{sample}/quant.sf"
    log:
        "logs/salmon_quant_{sample}.log"
    conda:
        "envs/bioinfo.yaml"
    threads: config["threads"]
    resources:
        mem_mb = 16000
    shell:
        """
        salmon quant -i {input.idx} -l A \
            -1 {input.r1} -2 {input.r2} \
            -p {threads} --gcBias \
            -o quant/salmon/{wildcards.sample} > {log} 2>&1
        """

rule star_index:
    input:
        fa = config["genome_fa"],
        gtf = config["gtf"]
    output:
        directory("ref/star_index")
    log:
        "logs/star_index.log"
    conda:
        "envs/bioinfo.yaml"
    threads: config["threads"]
    resources:
        mem_mb = 56000
    shell:
        """
        STAR --runThreadN {threads} --runMode genomeGenerate \
            --genomeDir {output} --genomeFastaFiles {input.fa} \
            --sjdbGTFfile {input.gtf} --sjdbOverhang {config[sjdb_overhang]} \
            --limitGenomeGenerateRAM {config[limit_genome_ram]} > {log} 2>&1
        """

rule star_align:
    input:
        idx = "ref/star_index",
        r1 = "trimmed/fastq/{sample}_1.trimmed.fastq.gz",
        r2 = "trimmed/fastq/{sample}_2.trimmed.fastq.gz"
    output:
        bam = "quant/star/{sample}_Aligned.sortedByCoord.out.bam"
    log:
        "logs/star_align_{sample}.log"
    conda:
        "envs/bioinfo.yaml"
    threads: config["threads"]
    resources:
        mem_mb = 40000
    shell:
        """
        STAR --runThreadN {threads} --genomeDir {input.idx} \
            --readFilesIn {input.r1} {input.r2} --readFilesCommand zcat \
            --outFileNamePrefix quant/star/{wildcards.sample}_ \
            --outSAMtype BAM SortedByCoordinate --quantMode GeneCounts > {log} 2>&1
        """

rule samtools_index:
    input:
        "quant/star/{sample}_Aligned.sortedByCoord.out.bam"
    output:
        "quant/star/{sample}_Aligned.sortedByCoord.out.bam.bai"
    log:
        "logs/samtools_index_{sample}.log"
    conda:
        "envs/bioinfo.yaml"
    threads: 2
    shell:
        "samtools index -@ {threads} {input} > {log} 2>&1"

rule featurecounts:
    input:
        bams = expand("quant/star/{sample}_Aligned.sortedByCoord.out.bam", sample=SAMPLES),
        gtf = config["gtf"]
    output:
        "quant/counts/gene_counts.txt"
    log:
        "logs/featurecounts.log"
    conda:
        "envs/bioinfo.yaml"
    threads: config["threads"]
    resources:
        mem_mb = 8000
    shell:
        """
        featureCounts -T {threads} -p --countReadPairs -B -C \
            -t exon -g gene_id -a {input.gtf} -o {output} {input.bams} > {log} 2>&1
        """

rule rseqc_sample:
    input:
        bam = "quant/star/{sample}_Aligned.sortedByCoord.out.bam",
        bai = "quant/star/{sample}_Aligned.sortedByCoord.out.bam.bai",
        bed = config["bed"]
    output:
        stat = "qc/rseqc/{sample}.bam_stat.txt",
        infer = "qc/rseqc/{sample}.infer_experiment.txt",
        dist = "qc/rseqc/{sample}.read_distribution.txt",
        inner = "qc/rseqc/{sample}.inner_distance.inner_distance_freq.txt"
    log:
        "logs/rseqc_{sample}.log"
    conda:
        "envs/qc.yaml"
    threads: 2
    resources:
        mem_mb = 8000
    shell:
        """
        bam_stat.py -i {input.bam} > {output.stat} 2> {log}
        infer_experiment.py -r {input.bed} -i {input.bam} > {output.infer} 2>> {log}
        read_distribution.py -r {input.bed} -i {input.bam} > {output.dist} 2>> {log}
        inner_distance.py -r {input.bed} -i {input.bam} -o qc/rseqc/{wildcards.sample}.inner_distance >> {log} 2>&1
        """

rule rseqc_genebody:
    input:
        bams = expand("quant/star/{sample}_Aligned.sortedByCoord.out.bam", sample=SAMPLES),
        bais = expand("quant/star/{sample}_Aligned.sortedByCoord.out.bam.bai", sample=SAMPLES),
        bed = config["pc_bed"]
    output:
        "qc/rseqc/all_samples.geneBodyCoverage.txt"
    log:
        "logs/rseqc_genebody.log"
    conda:
        "envs/qc.yaml"
    threads: 2
    resources:
        mem_mb = 16000
    shell:
        "geneBody_coverage.py -r {input.bed} -i quant/star/ -o qc/rseqc/all_samples > {log} 2>&1"

rule deeptools_qc:
    input:
        bams = expand("quant/star/{sample}_Aligned.sortedByCoord.out.bam", sample=SAMPLES),
        bais = expand("quant/star/{sample}_Aligned.sortedByCoord.out.bam.bai", sample=SAMPLES)
    output:
        npz = "qc/deeptools/results.npz",
        heatmap = "qc/deeptools/heatmap_SpearmanCorr.png",
        pca = "qc/deeptools/PCA_readCounts.png"
    log:
        "logs/deeptools_qc.log"
    conda:
        "envs/qc.yaml"
    threads: config["threads"]
    resources:
        mem_mb = 16000
    params:
        labels = " ".join(SAMPLES)
    shell:
        """
        multiBamSummary bins --bamfiles {input.bams} --labels {params.labels} -p {threads} -o {output.npz} > {log} 2>&1
        plotCorrelation -in {output.npz} --corMethod spearman --skipZeros --whatToPlot heatmap --colorMap RdYlBu_r --plotNumbers -o {output.heatmap} >> {log} 2>&1
        plotPCA -in {output.npz} -T "PCA of GSE52778 RNA-seq BAMs" -o {output.pca} >> {log} 2>&1
        """

rule multiqc:
    input:
        expand("qc/raw/{sample}_{read}_fastqc.html", sample=SAMPLES, read=[1, 2]),
        expand("qc/trimmed/{sample}_{read}.trimmed_fastqc.html", sample=SAMPLES, read=[1, 2]),
        expand("qc/fastp/{sample}_fastp.json", sample=SAMPLES),
        expand("quant/salmon/{sample}/quant.sf", sample=SAMPLES),
        "quant/counts/gene_counts.txt",
        expand("qc/rseqc/{sample}.bam_stat.txt", sample=SAMPLES),
        "qc/rseqc/all_samples.geneBodyCoverage.txt"
    output:
        "qc/multiqc/multiqc_report.html"
    log:
        "logs/multiqc.log"
    conda:
        "envs/qc.yaml"
    threads: 2
    shell:
        "multiqc qc/fastp qc/trimmed quant/star quant/counts quant/salmon qc/rseqc -o qc/multiqc --force > {log} 2>&1"
