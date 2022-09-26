#!/usr/bin/env bash

# Description:
# Push local ssh key at $HOME/.ssh/id_rsa.pub to 1 or all regions in AWS using the AWS CLI
# This script will also set the AWS_SSH_KEY_NAME variable used by ./addAdmin_workspace.sh
#
# TIP
# use source ./addAdmin_workspace.sh to update your current shell with AWS_SSH_KEY_NAME.

# Requirement:
# $HOME/.ssh/id_rsa.pub or create one with ssh-keygen.

# Usage Examples:
# The default with no args will create keypair name "my-aws-keypair-###" and copy it to all AWS regions
# source ./push-local-sshkeypair-to-aws.sh
#
# Create keypair name supplied in arg1 and copy to all AWS regions.
# source ./push-local-sshkeypair-to-aws.sh <my-keypair-name>
#
# Create keypair name supplied in arg1 and copy to region supplied in arg2.
# source ./push-local-sshkeypair-to-aws.sh <my-keypair-name> <aws-region>

# Create SSH key
ssh-keygen -t rsa -b 4096 -f $HOME/.ssh/tfc-hcpc-pipelines -N ''

# Path to PUBLIC ssh key that you want pushed to AWS
publickeyfile="$HOME/.ssh/tfc-hcpc-pipelines.pub"

# use supplied keypair name or by default create unique keypair name
if [[ -z "${1}" ]]; then
  unique_num=$(shuf -i 0-1000 -n 1)
  aws_keypair_name="my-aws-keypair-${unique_num}"
else
  aws_keypair_name="${1}"
fi
# source variable into the environment for ./addAdmin_workspace.sh
export AWS_SSH_KEY_NAME=${aws_keypair_name}
echo "AWS_SSH_KEY_NAME=${aws_keypair_name}"

# set target region or by default all available regions will be used.

if [[ ! -z ${AWS_DEFAULT_REGION} && -z "${2}" ]]; then
  regions="${AWS_DEFAULT_REGION}"
  echo $regions
elif [[ ! -z "${2}" ]]; then
  regions="${2}"
  echo $regions
else
  regions=$(aws ec2 describe-regions \
  --output text \
  --query 'Regions[*].RegionName')
  echo $regions
fi

for region in $regions; do
  echo "Importing keypair: $aws_keypair_name to $region"
  aws ec2 import-key-pair \
    --region "$region" \
    --key-name "$aws_keypair_name" \
    --public-key-material "fileb://$publickeyfile"
done
