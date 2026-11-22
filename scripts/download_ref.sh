#!/bin/bash
set -euo pipefail	# exit if any  errors, if undef exit, or if command fails = pipeline fails

# create directory if it doensn't exist yet and enter the directory
mkdir -p ref && cd ref

# downloads the refference genomes -c - resume flag if download fails. Continues where it has stopped
# so you don't need to initialize download again

wget -c https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_50/GRCh38.primary_assembly.genome.fa.gz
wget -c https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_50/gencode.v50.primary_assembly.annotation.gtf.gz
wget -c https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_50/gencode.v50.transcripts.fa.gz


# fetches the contents of EBIS MD5SUM file and prints it to stdout.
# - s = silent. Hides curls progress bar and error meters, only md5sums is passes down the pipe
# grep -E "..." = filters the long MD5SUMS list to only 3 lines matvhing the files dwonlaoded
# -E = enables extended regular expressions "|" acts as or
#   md5sum -c = reads checksums and filenames and verifys them "OK" "FAILED"

curl -s https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_50/MD5SUMS \
  | grep -E "GRCh38\.primary_assembly\.genome\.fa\.gz|gencode\.v50\.primary_assembly\.annotation\.gtf\.gz|gencode\.v50\.transcripts\.fa\.gz" \
  | md5sum -c -
