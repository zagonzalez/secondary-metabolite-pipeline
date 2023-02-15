#! /bin/bash

# ***** Customize based on contents of input file and parameters to the Docker entry point
container="BGC_bacteria"
# Add variable to specify the docker container
#container_job_name=
rip_dir="/EFS/RunsInProgress"
program_dir="$rip_dir/$container"
EC2_type="ON_DEMAND"
skip_s3_file_check="false"

# Run Docker container for each line in an input file
# Copyright 2022, SolareaBio

input_csv=""
# output_dir=""
job_name=BGC_bacteria
job_queue=BGC_bacteria_ON_DEMAND_JQ
job_definition="BGC_bacteria_JD"

usage() {
  cat << EOF
Usage $0 -i <.csv file>
Generates antismash, deepbgc, and BAGEL results for the given samples
This should be run from the EFS so that it can download the antismash database to /EFS/RunsInProgress/BGC_bacteria
Since this is just a single Docker container, the antismash database will need to be manually deleted afterwards
-i <.csv file>      Input .csv file with two columns (no header):
                    Sample name (ie SBIxxxxx)
                    Full filepath of contigs file on S3 (ie s3://solareabio-sequencing/SBI/SBIxxxxx/02.assembly/contigs.fasta)
-s                  Skip check for presence of files on S3
EOF
}

while getopts "i:s" option; do
  case $option in
    i)  input_csv=$OPTARG;;
    s)  skip_s3_file_check="true";;
    h) usage; exit;;
    [?]) usage; exit;;
  esac
done

if [[ -z $input_csv ]]; then usage; echo; echo "Input .csv is required"; exit; fi

# Download antismash database
# Make sure the /EFS/RunsInProgress directory exists
if [[ ! -d "$rip_dir" ]]; then
    echo "Please run this script from the EFS"
    exit 1
fi

# Make sure all the input files exist on S3
#if [[ "$skip_s3_file_check" == "false" ]]; then
  #echo "Checking for presence of S3 files..."
  #aws s3 ls --recursive s3://solareabio-sequencing/SBI > SBI_listing.txt
  # ASK ABOUT THIS ABOVE LINE OF CODE - FNA SAMPLES ARE ON EFS - SHOULD THIS INPUT BE DIRECTED TO EFS?
  #found_all_inputs=true
  #while read -r line || [[ -n "$line" ]]; do
    #sample_name=$(echo $line | tr -d '\r' | cut -d',' -f1)
    #s3_fna=$(echo $line | tr -d '\r' | cut -d',' -f2 | sed 's;s3://solareabio-sequencing/;;')
    #s3_faa=$(echo $line | tr -d '\r' | cut -d',' -f3 | sed 's;s3://solareabio-sequencing/;;')

    #found_sample_inputs=true
    #fna_grep_line=$(cat SBI_listing.txt | (grep $s3_fna || :))
    #if [[ $fna_grep_line == "" ]]; then
      #echo "$sample_name: Contigs file not found: $s3_fna"
      #found_sample_inputs=false
    #else
      #length=$(echo "$fna_grep_line" | xargs | cut -d" " -f3)
      #if [[ $length == "0" ]]; then
        #echo "$sample_name: Contigs file ($s3_fna) has size of 0"
        #found_sample_inputs=false
      #fi
    #fi
    #if [[ $found_sample_inputs != "true" ]]; then
      #found_all_inputs=false
    #fi
  #done < "$input_csv"
  #if [[ $found_all_inputs != true ]]; then
    #exit 1
  #fi
#fi

run_id=$(date '+%Y%m%d%H%M%S')
# Copy the input file to s3://solareabio-analyses/BGC_bacteria/$run_id
s3_base='s3://solareabio-analyses'
s3_dir=$s3_base/$container/$run_id
run_dir=$program_dir/$run_id
group_name=$(basename $input_csv .csv)
group_dir=$run_dir/$group_name
aws s3 cp $input_csv $s3_dir/$(basename $input_csv)
# Split the input file into multiple files with up to 100 lines each
# and place the files in /EFS/RunsInProgress/BGC_bacteria/$run_id
#mkdir -p -m=2775 $program_dir/$run_id
#split -l 100 -d -a 2 --additional-suffix=.csv $input_csv $program_dir/$run_id/${run_id}_

#input_files=$(find $program_dir/$run_id -name "${run_id}_*")

#deepbgc download

# Retrieve all of the contig fna files
while read -r line || [[ -n "$line" ]]; do
    sample_name=$(echo $line | tr -d '\r' | xargs | cut -d',' -f1)
    sample_fna=$(echo $line | tr -d '\r' | xargs | cut -d',' -f2)
    #sample_type=$(echo $line | tr -d '\r' | xargs | cut -d',' -f3 | "Meta" = $ )
    echo "SampleName: $sample_name"

    aws batch submit-job \
        --job-name $job_name \
        --job-queue $job_queue \
        --job-definition $job_definition \
        --parameters '{"sample_name":"'$sample_name'","sample_fna":"'$sample_fna'","run_id":"'$run_id'","outdir_base":"'$group_dir'","s3_dir":"'$s3_dir'"}'
done < "$input_csv"
