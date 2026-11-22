#!/bin/bash
set -euo pipefail			# e -exit immeadiately 
							# u Treat undef var as an error
							# o if any comman fails, pipeline fails


# --- Paths ---
ACCESSION="data/accessions.txt"
OUTPUT="raw/fastq"
TMP_DIR="tmp_sra"
THREADS=4
						
mkdir -p "$OUTPUT" "$TMP_DIR"	# -p creates folders if they dont exist
								# skips if they do
if [ ! -f "$ACCESSION" ]; then	# if no file then error
    echo "Error: $ACCESSION not found."
    exit 1
fi

while IFS= read -r acc || [ -n "$acc" ]; do
    # Removes invisible line endings and space, tabs
    acc=$(echo "$acc" | tr -d '\r[:space:]')
    [ -z "$acc" ] && continue	# if line is blank continue

    # Check if fastq.gz  files for this accession already exist
    if compgen -G "$OUTPUT/${acc}*.fastq.gz" > /dev/null; then
        echo "[SKIP] $acc is already downloaded."
        continue
    fi

	# orefetch - NCBI sra  tool for downloading sra. default size = 20gb
    echo "[START] Downloading $acc..."
    prefetch --max-size 100G -O "$TMP_DIR" "$acc"

	# fasterq-dump SRA toolkit, unpacks sra to fastq files
    echo "[EXTRACT] Converting $acc to FASTQ..."

    # seperates paired end deq into two files, uses 4 cpus, stores
    # temp scratch files into TMP_DIR, writed output files to
    # output folder (raw/fastq)
    fasterq-dump --split-files -e "$THREADS" -t "$TMP_DIR" -O "$OUTPUT" "$TMP_DIR/$acc"


	# compresses the large files into fastq.gz
    echo "[COMPRESS] Gzipping $acc..."
    gzip "$OUTPUT/${acc}"*.fastq

    # Clean up raw .sra folder immediately to save disk space
    rm -rf "$TMP_DIR/$acc"
    echo "[DONE] $acc finished."

done < "$ACCESSION"

echo "All accessions processed."
