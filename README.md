# secondary-metabolite-pipeline

## Name
Zachary Gonzalez

## Description
The following pipeline takes in bacterial genome contig files. The contig files are run through a set of Biosynthetic Gene Cluster mining tools (antiSMASH, DeepBGC, and BAGEL) that mine the diveristy of the clusters within each sample. 

The three tools generate three output folders for each sample (one folder per tool). Each tool generates a file of varying format containing information regarding BGC product classes. A python script was generated to read these files and create a single output file containing relevant information on the BGC product classes for each sample. 

The pipeline container is setup using the docker file (BGC_bacteria.dockerfile) that stores the environmental packages and dependencies and the setup script (setup_BGC_bacteria.sh). The script register_job_def_check_efs_access ensures the job has access to the server containing the input files. The script run_long_process is used to run the tools more efficiently. The summary python script compiles the BGC product data from the output of the three tools. 

## Running the pipeline
The pipeline takes in one input file - this input file contains the paths to the contig files
The command to run the script is the following:
./run_BGC_bacteria.sh -i input_filename
The run_BGC_bacteria.sh calls to the BGC_bacteria.sh script with the commands to run the three BGC mining tools. 
