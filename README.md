# secondary-metabolite-pipeline

## Name
Zachary Gonzalez

## Date
2/15/23

## Description
The following pipeline takes in bacterial genome contig files. The contig files are run through a set of Biosynthetic Gene Cluster mining tools (antiSMASH, DeepBGC, and BAGEL) that mine the diveristy of the clusters within each sample. A python script then outputs relevant information regarding BGC product classes for each sample in a clear and readable manner. 

The pipeline is set up on an AWS environment via a docker container. This allows for the a large number of samples to be run in parallel and greatly increases the pipeline efficiency with spot instance. 

## Running thee pipeline
The pipeline takes in one input file - this input file contains the paths to the contig files
The command to run the script is the following:
./run_BGC_bacteria.sh -i input_filename
