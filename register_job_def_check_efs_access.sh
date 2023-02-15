

# Register job definition
job_definition="${container}_JD"
jd_info=$(aws batch describe-job-definitions --status ACTIVE --job-definition-name $job_definition)
jd_status=$(echo $jd_info | jq '.jobDefinitions[0] | .status // ""' | tr -d '"')
if [[ $jd_status != "ACTIVE" ]]; then
  aws batch register-job-definition \
    --job-definition-name $job_definition \
    --type container \
    --container-properties '{"privileged":true,"image":"'$repo/$image_and_tag'","vcpus":'${vCPUs_req}',"memory":'${memory_MiB_req}',"mountPoints":[{"sourceVolume":"SB-EFS","containerPath":"/EFS"}],"volumes":[{"host":{"sourcePath":"/"},"name":"SB-EFS"}],"command":["Ref::container","Ref::run_id","Ref::input_file"]}' \
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