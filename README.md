# secondary-metabolite-pipeline

## Name
Zachary Gonzalez

## Date
2/15/23

## Description
The following pipeline takes in bacterial genome contig files. The contig files are run through a set of Biosynthetic Gene Cluster mining tools (antiSMASH, DeepBGC, and BAGEL) that mine the diveristy of the clusters within each sample. 

The three tools generate three output folders for each sample (one folder per tool). Each tool generates a file of varying format containing information regarding BGC product classes. A python script was generated to read these files and create a single output file containing relevant information on the BGC product classes for each sample. 

The pipeline is run on AWS via a docker container so that a large number of samples can be run in parallel. This also allows for the usage of spot instance to increase pipeline efficiency. 

## Running thee pipeline
The pipeline takes in one input file - this input file contains the paths to the contig files
The command to run the script is the following:
./run_BGC_bacteria.sh -i input_filename
