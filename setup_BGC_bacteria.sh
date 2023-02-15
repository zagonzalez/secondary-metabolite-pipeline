#! /bin/bash

# Setup the AWS Batch architecture
# Copyright 2022, SolareaBio

set -e


# ***** BEGIN custom lines

container="BGC_bacteria"
#container_meta="BGC_Metagenomes"
vCPUs_req=12
memory_MiB_req=40000
#CUSTOM CPU AND MEMORY SETTINGS

# ***** END custom lines



container_lc=$(echo $container | tr [A-Z] [a-z])
#container_lc_meta=$(echo $container_meta | tr [A-Z] [a-z])

subnet_useast1a="subnet-42371d0a"
subnet_useast1b="subnet-b03c54ea"
subnet_useast1c="subnet-00ee1364"

usage() {
  cat << EOF
Usage $0 [-h]

Builds the $container docker container, pushes it to the AWS ECR, and sets up the $container AWS Batch environment
EOF
}

while getopts "h" option; do
  case $option in
    h)   usage;exit;;
    [?]) usage; exit;;
  esac
done

script_dir=$(dirname "$0")

repo="990850896279.dkr.ecr.us-east-1.amazonaws.com"
#repo_meta="990850896279.dkr.ecr.us-east-1.amazonaws.com"

echo "Logging into ECR"
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${repo} #${repo_meta}

image_and_tag="${container_lc}:latest"
#image_and_tag_meta="${container_lc_meta}:latest"
echo "Building the docker container: $image_and_tag"

# If you get errors from the docker build command, try adding --no-cache
docker build -f $script_dir/${container}.dockerfile -t $image_and_tag $script_dir
#docker build -f $script_dir/${container_meta}.dockerfile -t $image_and_tag_meta $script_dir

echo "Tagging Image"
docker tag ${image_and_tag} ${repo}/${image_and_tag}
#docker tag ${image_and_tag_meta} ${repo_meta}/${image_and_tag_meta}

# Create repository in AWS ECR
repo_container_info=$(aws ecr describe-repositories --repository-names ${container_lc} #${container_lc_meta})
if [[ "$repo_container_info" == "" ]]; then
  aws ecr create-repository --repository-name ${container_lc}
  #aws ecr create-repository --repository-name ${container_lc_meta}
fi

echo "Pushing Image up to AWS"
docker push ${repo}/${image_and_tag}
#docker push ${repo_meta}/${image_and_tag_meta}

# Create compute environment
EC2_type=ON_DEMAND
ce_info=$(aws batch describe-compute-environments --compute-environments ${container}_${EC2_type}_CE)
ce_status=$(echo $ce_info | jq '.computeEnvironments[0] | .status // ""' | tr -d '"')
if [[ $ce_status != "VALID" ]]; then
  compute_resources='{"type":"EC2","allocationStrategy":"BEST_FIT_PROGRESSIVE","minvCpus":0,"maxvCpus":10000,"tags":{"Name":"'${container}_Batch'"},"instanceTypes":["c5a","m5a","c5","m5"],"subnets":["'$subnet_useast1a'","'$subnet_useast1b'","'$subnet_useast1c'"],"securityGroupIds":["sg-ff2fd48f","sg-65ff5315"],"ec2KeyPair":"SBTools","instanceRole":"ecsInstanceRole"}'
  aws batch create-compute-environment \
    --compute-environment-name ${container}_${EC2_type}_CE \
    --type MANAGED \
    --state ENABLED \
    --compute-resources $compute_resources \
    --service-role AWSBatchServiceRole

  printf "Waiting for Compute Environment to be created"
  while [[ $ce_status != "VALID" ]]; do
    sleep 5
    printf "."
    ce_info=$(aws batch describe-compute-environments --compute-environments ${container}_${EC2_type}_CE)
    ce_status=$(echo $ce_info | jq '.computeEnvironments[0] | .status // ""' | tr -d '"')
  done
  echo ""
fi

# Create the job queue
jq_info=$(aws batch describe-job-queues --job-queues ${container}_${EC2_type}_JQ)
jq_status=$(echo $jq_info | jq '.jobQueues[0] | .status // ""' | tr -d '"')
if [[ $jq_status != "VALID" ]]; then
  aws batch create-job-queue \
    --job-queue-name ${container}_${EC2_type}_JQ \
    --state ENABLED \
    --priority 5 \
    --compute-environment-order '{"order":1,"computeEnvironment":"'${container}_${EC2_type}_CE'"}'
fi

# Register job definition
job_definition="${container}_JD"
jd_info=$(aws batch describe-job-definitions --status ACTIVE --job-definition-name $job_definition)
jd_status=$(echo $jd_info | jq '.jobDefinitions[0] | .status // ""' | tr -d '"')
if [[ $jd_status != "ACTIVE" ]]; then
  aws batch register-job-definition \
    --job-definition-name $job_definition \
    --type container \
    --container-properties '{"privileged":true,"image":"'$repo/$image_and_tag'","vcpus":'${vCPUs_req}',"memory":'${memory_MiB_req}',"mountPoints":[{"sourceVolume":"SB-EFS","containerPath":"/EFS"}],"volumes":[{"host":{"sourcePath":"/"},"name":"SB-EFS"}],"command":["Ref::sample_name","Ref::sample_fna","Ref::run_id","Ref::outdir_base","Ref::s3_dir"]}' \
    --retry-strategy '{"attempts": 10,"evaluateOnExit":[{"onStatusReason" :"Host EC2*","action": "RETRY"},{"onReason" : "*","action": "EXIT"}]}'
fi

# Make sure the EFS has an access point set up
efs_id=$(aws efs describe-file-systems | jq -r '.FileSystems[] | select (.Name=="SB-EFS") | .FileSystemId')
if [[ "$efs_id" == "" ]]; then
  echo "ERROR: SB-EFS does not exist"
  exit
fi
ap_id=$(aws efs describe-access-points | jq -r '.AccessPoints[] | select (.Name=="EFS_AP") | .AccessPointId')
if [[ "$ap_id" == "" ]]; then
  # 1001:1001 is user sb in group sb
  ap_id=$(aws efs create-access-point --file-system-id "$efs_id" --posix-user '{"Uid":1001,"Gid":1001}' --root-directory '{"Path":"/"}' --tags '[{"Key":"Name","Value":"EFS_AP"}]' | jq -r '.AccessPointId')
fi
