#!/bin/bash

# Script to be run within the Docker container
# Copyright 2022, SolareaBio

# ***** BEGIN common execution lines

set -ex


source ./run_long_process.sh

# Mount the EFS (nfs-common is installed in the .dockerfile)
mkdir -p /EFS
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 fs-5403651d.efs.us-east-1.amazonaws.com:/ /EFS

# Enable group write for new files and folders
umask 002

rip_dir="/EFS/RunsInProgress"
num_threads_present=$(grep -c processor /proc/cpuinfo)
num_threads=$(echo "$num_threads_present-1" | bc) 

# ***** END common execution lines


# ***** BEGIN custom execution lines
sample_name="$1"
sample_fna="$2"
run_id="$3"
outdir_base="$4"
s3_dir="$5"


sample_dir=$outdir_base/$sample_name
mkdir -p -m=2775 $sample_dir

fna_dir=$sample_dir/fna
mkdir -p -m=2775 $fna_dir
efs_fna=$fna_dir/$sample_name.fna
cp $sample_fna $efs_fna

#"run antiSMASH, DeepBGC, and BAGEL on all sample files"
echo "running antismash"
antismash_cmd="antismash --databases /EFS/database/antismash --genefinding-tool prodigal -c 30 --cb-general --cb-knownclusters --cb-subclusters --asf --pfam2go --smcog-trees --tigrfam --cc-mibig --output-dir $sample_dir/antismash2 $efs_fna"
run_long_process "$antismash_cmd"

#echo "running DeepBGC"
#conda init bash
source /EFS/tools/miniconda/etc/profile.d/conda.sh
conda activate deepbgc2
deepbgc download
#set hmmer to run on more cpu's
#setenv HMMER_NCPU 16
deepbgc_cmd="deepbgc pipeline $efs_fna -o $sample_dir/Deepbgc"
run_long_process "$deepbgc_cmd"

echo "running BAGEL4"
source /EFS/EnvSetup/Metagenomes-Analysis.sh
BAGEL_cmd="/EFS/tools/BAGEL/bagel4_2022/bagel4_wrapper.pl -s $sample_dir/Bagel4 -query $fna_dir -r $sample_name.fna"
run_long_process "$BAGEL_cmd"

aws s3 sync $sample_dir $s3_dir/$sample_name

# Remove the group directory
# For safety, to avoid removing something too close to the root, make sure dir length is longer than /EFS/RunsInProgress/CCTax/YYYYMMDDHHMMSS
#if [[ ${#group_dir} -gt 40 ]]; then
#    rm -rf "$group_dir"
#fi

# ***** END custom execution lines