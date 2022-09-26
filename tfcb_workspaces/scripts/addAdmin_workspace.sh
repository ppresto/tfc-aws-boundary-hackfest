#!/bin/bash
# This Script creates an ADMIN workspace in TFCB if it does not already exist,
# and adds standard terraform & env variables to it using your current host environment.
# This requires Terraform Cloud (Free Tier) with Github integration setup can configured with a github repo with this code.

# WARNING:
# This workspace can manage all sensitive data within your org.
# It should be locked down to owners only and will contain sensitive data in clear text.

# REQUIRED ENV VARIABLES:
# export TFC_TOKEN    #Use TFE owners team token for proper TFC access
# export TFC_ORGANIZATION  # Use your TFC organization name to connect to TFC
# export TFC_GIT_OAUTH_TOKEN_ID #Github OAuth App Token used to setup VCS integration
# export HCP_CLIENT_ID
# export HCP_CLIENT_SECRET
# Export your AWS credentials to have them managed by the TFCB admin workspace:
# export AWS_SECRET_ACCESS_KEY=""
# export AWS_ACCESS_KEY_ID=""
#
# Next update each file ./tfcb_workspaces/<workspace>.tf
#
#  tf_variables_sec = {
#    "AWS_ACCESS_KEY_ID" = var.aws_access_key_id
#    "AWS_SECRET_ACCESS_KEY" = var.aws_secret_access_key
#  }
#
# Note: There are many different ways to manage creds in TFC depending on your security level.
#       These creds will be encrypted in each child workspace.  They will be clear text in the
#       admin workspace which should be locked down.  Additional TFC workflows are available for stronger security.

# Set TFE Address
# Set Organization - This is your TFCB Organization name
# Set Admin Workspace Name
# Set workspace -  Github repo the Admin Workspace will use (Should point to this code)
# Set WORKSPACE_DIR - subfolder to manage TFCB workspaces

# Usage:
# Optional inputs can be used to override your github repo URL and workspace name.
#
# ./addAdmin_workspace.sh
#

# Provide your TFCB, and Github information
address="app.terraform.io"
#  Github Repo URL
git_url="https://github.com/ppresto/tfc-hcpc-pipelines.git"
# Admin Workspace Name
workspace="admin_tfc_workspaces"
# This is the repo dir TFCB will use to run terraform and manage your workspaces with IaC
WORKSPACE_DIR="tfcb_workspaces"
BRANCH="main"
TF_VERSION="1.1.4"

# set sensitive TFC, HCP environment variables/tokens
#TFC_ORGANIZATION="Patrick"
#source $HOME/tfeSetEnv.sh "${TFC_ORGANIZATION}"
#source $HOME/hcpSetEnv.sh

# Set git_url
if [ ! -z $1 ]; then
  git_url=$1
fi
echo "Using Github repo: $git_url"

# workspace name should not have spaces
if [ ! -z "$2" ]; then
  workspace=$2
fi
echo "Using workspace name: " $workspace

if [ -z ${TFC_GIT_OAUTH_TOKEN_ID} ]; then
  echo "ERROR:  Set your Github Env variable TFC_GIT_OAUTH_TOKEN_ID to your oauth token to allow TFC to connect to github"
  exit 1
fi

if [ -z ${TFC_TOKEN} ]; then
  echo "ERROR:  Set your TFE Env variable TFC_TOKEN to connect to TFC"
  exit 1
fi
if [ -z ${TFC_ORGANIZATION} ]; then
  echo "ERROR:  Set your Github Organization variable TFC_ORGANIZATION to enable VCS integration"
  exit 1
fi
if [ -z ${HCP_CLIENT_ID} ]; then
  echo "ERROR:  Set your HCP_CLIENT_ID variable to connect to HCP." 
  echo "If you dont have an HCP account create one here: https://portal.cloud.hashicorp.com/sign-up"
  echo "See how to create your Client ID and Secret here: https://www.youtube.com/watch?v=0CgqO1WzyPU"
  exit 1
fi
if [ -z ${HCP_CLIENT_SECRET} ]; then
  echo "ERROR:  Set your HCP_CLIENT_SECRET variable to connect to HCP."
  echo "If you dont have an HCP account create one here: https://portal.cloud.hashicorp.com/sign-up"
  echo "See how to create your Client ID and Secret here: https://www.youtube.com/watch?v=0CgqO1WzyPU"
  exit 1
fi
if [ -z ${AWS_DEFAULT_REGION} ]; then
  echo "ERROR:  Set your AWS_DEFAULT_REGION variable to your default region (ex: us-west-2)."
  exit 1
fi
if [ -z ${AWS_SSH_KEY_NAME} ]; then
  echo "ERROR:  Set your AWS_SSH_KEY_NAME variable to your AWS ssh key pair name.  This is needed to ssh to your ec2 and eks nodes."
  echo "If you dont have an ssh key in the region you want to provision in, you can create one following these instructions here: https://docs.aws.amazon.com/ground-station/latest/ug/create-ec2-ssh-key-pair.html"
  echo "If you want to copy your local key to AWS run ./push-local-sshkeypair-to-aws.sh"
  exit 1
fi

function addKeyVars () {
# Provide 3 Inputs: key_name , key_value, boolean (to enable encryption).
  tee variable.json <<EOF
{
  "data": {
    "type":"vars",
    "attributes": {
      "key":"${1}",
      "value":"${2}",
      "category":"terraform",
      "hcl":false,
      "sensitive":${3}
    }
  },
  "filter": {
    "organization": {
      "username":"TFC_ORGANIZATION"
    },
    "workspace": {
      "name":"${workspace}"
    }
  }
}
EOF

}

# You can change sleep duration if desired
sleep_duration=5
save_plan="false"
applied="false"

# Get first argument.
# If not "", Set to git clone URL
# and clone the git repository
# If "", then load code from config directory

# Setup GitHub, Config Dir, and Repo
  config_dir=$(echo $git_url | cut -d "/" -f 5 | cut -d "." -f 1)
  repository=$(echo $git_url | cut -d "/" -f 4,5 | cut -d "." -f 1)

# Make sure $workspace does not have spaces
if [[ "${workspace}" != "${workspace% *}" ]] ; then
    echo "The workspace name cannot contain spaces."
    echo "Please pick a name without spaces and run again."
    exit
fi

# build compressed tar file from configuration directory
#echo "Tarring configuration directory."
#tar -czf ${config_dir}.tar.gz -C ${config_dir} --exclude .git .
# workspace attributes
#Set name of workspace in workspace.json
sed "s/workspace_name/${workspace}/" < workspace.template.json > workspace.json
#Set githib repo for workspace
sed -i.backup "s/org\/workspace_repo/${repository/\//\\/}/g" ./workspace.json
sed -i.backup "s/main/${BRANCH}/g" ./workspace.json

#Set my github org oauth token
sed -i.backup "s/oauth_token_id/${TFC_GIT_OAUTH_TOKEN_ID}/g" ./workspace.json
sed -i.backup "s/workspace_dir/${WORKSPACE_DIR//\//\\/}/g" ./workspace.json
sed -i.backup "s/VERSION/${TF_VERSION}/g" ./workspace.json

# Check to see if the workspace already exists
echo "Checking to see if workspace exists"
check_workspace_result=$(curl -s --header "Authorization: Bearer $TFC_TOKEN" --header "Content-Type: application/vnd.api+json" "https://${address}/api/v2/organizations/${TFC_ORGANIZATION}/workspaces/${workspace}")

echo $check_workspace_result
# Parse workspace_id from check_workspace_result
#workspace_id=$(echo $check_workspace_result | python -c "import sys, json; print(json.load(sys.stdin)['data']['id'])")
workspace_id=$(echo $check_workspace_result | jq -r '.data.id')
echo "Workspace ID: " $workspace_id

# Create workspace if it does not already exist
if [ "$workspace_id" == 'null' ]; then
  echo "Workspace did not already exist; will create it."
  workspace_result=$(curl -s --header "Authorization: Bearer $TFC_TOKEN" --header "Content-Type: application/vnd.api+json" --request POST --data @workspace.json "https://${address}/api/v2/organizations/${TFC_ORGANIZATION}/workspaces")
  if [[ ! $? ]]; then
    echo ""
    echo "Error creating TFC workspace at ${address} using current TFC_TOKEN, or TFC_ORGANIZATION"
    echo "Test API connectivity by querying for workspace name"
    echo "curl -s --header \"Authorization: Bearer $TFC_TOKEN\" --header \"Content-Type: application/vnd.api+json\" \"https://${address}/api/v2/organizations/${TFC_ORGANIZATION}/workspaces/${workspace}\""
    exit
  fi
  echo "Checking Workspace Result: $workspace_result"
  # Parse workspace_id from workspace_result
  #workspace_id=$(echo $workspace_result | python -c "import sys, json; print(json.load(sys.stdin)['data']['id'])")
  workspace_id=$(echo $workspace_result | jq -r '.data.id')
  echo "Workspace ID: " $workspace_id
else
  echo "Workspace already existed."
fi

# Check if a variables.csv file is in the configuration directory
# If so, use it. Otherwise, use the one in the current directory.
#if [ -f "${config_dir}/variables.csv" ]; then
#  echo "Found variables.csv in ${config_dir}."
#  echo "Will load variables from it."
#  variables_file=${config_dir}/variables.csv
#else
#  echo "Will load variables from ./variables.csv"
#  variables_file=variables.csv
#fi


# Add variables to workspace
#while IFS=',' read -r key value category hcl sensitive
#do
#  sed -e "s/my-organization/TFC_ORGANIZATION/" -e "s/my-workspace/${workspace}/" -e "s/my-key/$key/" -e "s/my-value/$value/" -e "s/my-category/$category/" -e "s/my-hcl/$hcl/" -e "s/my-sensitive/$sensitive/" < variable.template.json  > variable.json
#  echo "Adding variable $key with value $value in category $category with hcl $hcl and sensitive $sensitive"
#  upload_variable_result=$(curl -s --header "Authorization: Bearer $TFC_TOKEN" --header "Content-Type: application/vnd.api+json" --data @variable.json "https://${address}/api/v2/vars?filter%5Borganization%5D%5Bname%5D=${TFC_ORGANIZATION}&filter%5Bworkspace%5D%5Bname%5D=${workspace}")
#done < ${variables_file}

# Set CONFIRM_DESTROY as a default Environment variable
sed -e "s/my-organization/TFC_ORGANIZATION/" -e "s/my-workspace/${workspace}/" -e "s/my-key/CONFIRM_DESTROY/" -e "s/my-value/1/" -e "s/my-category/env/" -e "s/my-hcl/false/" -e "s/my-sensitive/false/" < variable.template.json  > variable.json
echo "Adding CONFIRM_DESTROY"
upload_variable_result=$(curl -s --header "Authorization: Bearer $TFC_TOKEN" --header "Content-Type: application/vnd.api+json" --data @variable.json "https://${address}/api/v2/vars?filter%5Borganization%5D%5Bname%5D=${TFC_ORGANIZATION}&filter%5Bworkspace%5D%5Bname%5D=${workspace}")

# Add Personal - AWS SSH Key Pair
if [[ ! -z ${AWS_SSH_KEY_NAME} ]]; then
  # AWS_DEFAULT_REGION
  sed -e "s/my-organization/TFC_ORGANIZATION/" -e "s/my-workspace/${workspace}/" -e "s/my-key/ssh_key_name/" -e "s/my-value/${AWS_SSH_KEY_NAME}/" -e "s/my-category/terraform/" -e "s/my-hcl/false/" -e "s/my-sensitive/false/" < variable.template.json  > variable.json
  echo "Adding AWS_SSH_KEY_NAME:  $AWS_SSH_KEY_NAME"
  upload_variable_result=$(curl -s --header "Authorization: Bearer $TFC_TOKEN" --header "Content-Type: application/vnd.api+json" --data @variable.json "https://${address}/api/v2/vars?filter%5Borganization%5D%5Bname%5D=${TFC_ORGANIZATION}&filter%5Bworkspace%5D%5Bname%5D=${workspace}")
fi

if [ ! -z ${TFC_GIT_OAUTH_TOKEN_ID} ]; then
  # TFC_GIT_OAUTH_TOKEN_ID
  sed -e "s/my-organization/TFC_ORGANIZATION/" -e "s/my-workspace/${workspace}/" -e "s/my-key/oauth_token_id/" -e "s/my-value/${TFC_GIT_OAUTH_TOKEN_ID}/" -e "s/my-category/terraform/" -e "s/my-hcl/false/" -e "s/my-sensitive/false/" < variable.template.json  > variable.json
  echo "Adding OAUTH_TOKEN_ID"
  upload_variable_result=$(curl -s --header "Authorization: Bearer $TFC_TOKEN" --header "Content-Type: application/vnd.api+json" --data @variable.json "https://${address}/api/v2/vars?filter%5Borganization%5D%5Bname%5D=${TFC_ORGANIZATION}&filter%5Bworkspace%5D%5Bname%5D=${workspace}")
fi

if [ ! -z ${TFC_TOKEN} ]; then
  # TFC_TOKEN
  sed -e "s/my-organization/$TFC_ORGANIZATION/" -e "s/my-workspace/${workspace}/" -e "s/my-key/tfe_token/" -e "s/my-value/${TFC_TOKEN}/" -e "s/my-category/terraform/" -e "s/my-hcl/false/" -e "s/my-sensitive/false/" < variable.template.json  > variable.json
  echo "Adding TFC_TOKEN"
  upload_variable_result=$(curl -s --header "Authorization: Bearer $TFC_TOKEN" --header "Content-Type: application/vnd.api+json" --data @variable.json "https://${address}/api/v2/vars?filter%5Borganization%5D%5Bname%5D=${TFC_ORGANIZATION}&filter%5Bworkspace%5D%5Bname%5D=${workspace}")
fi

if [ ! -z ${TFC_ORGANIZATION} ]; then
  # organization
  sed -e "s/my-organization/$TFC_ORGANIZATION/" -e "s/my-workspace/${workspace}/" -e "s/my-key/organization/" -e "s/my-value/${TFC_ORGANIZATION}/" -e "s/my-category/terraform/" -e "s/my-hcl/false/" -e "s/my-sensitive/false/" < variable.template.json  > variable.json
  echo "Adding TFC_ORGANIZATION: ${TFC_ORGANIZATION}"
  upload_variable_result=$(curl -s --header "Authorization: Bearer $TFC_TOKEN" --header "Content-Type: application/vnd.api+json" --data @variable.json "https://${address}/api/v2/vars?filter%5Borganization%5D%5Bname%5D=${TFC_ORGANIZATION}&filter%5Bworkspace%5D%5Bname%5D=${workspace}")
fi

if [ ! -z ${repository} ]; then
  # repository
  sed -e "s/my-organization/$TFC_ORGANIZATION/" -e "s/my-workspace/${workspace}/" -e "s/my-key/repo_org/" -e "s/my-value/${repository%/*}/" -e "s/my-category/terraform/" -e "s/my-hcl/false/" -e "s/my-sensitive/false/" < variable.template.json  > variable.json
  echo "Adding Github org ${repository%/*}"
  upload_variable_result=$(curl -s --header "Authorization: Bearer $TFC_TOKEN" --header "Content-Type: application/vnd.api+json" --data @variable.json "https://${address}/api/v2/vars?filter%5Borganization%5D%5Bname%5D=${TFC_ORGANIZATION}&filter%5Bworkspace%5D%5Bname%5D=${workspace}")
fi

# Build Azure Credentials
# example template replacement
# sed -e "s/my-organization/$TFC_ORGANIZATION/" -e "s/my-workspace/${workspace}/" -e "s/my-key/$key/" -e "s/my-value/$value/" -e "s/my-category/$category/" -e "s/my-hcl/$hcl/" -e "s/my-sensitive/$sensitive/" < variable.template.json  > variable.json

if [[ ! -z ${ARM_CLIENT_ID} && ! -z ${ARM_SUBSCRIPTION_ID} && ! -z ${ARM_CLIENT_SECRET} && ! -z ${ARM_TENANT_ID} ]]; then
  # ARM_CLIENT_ID
  sed -e "s/my-organization/$TFC_ORGANIZATION/" -e "s/my-workspace/${workspace}/" -e "s/my-key/arm_client_id/" -e "s/my-value/${ARM_CLIENT_ID}/" -e "s/my-category/terraform/" -e "s/my-hcl/false/" -e "s/my-sensitive/false/" < variable.template.json  > variable.json
  echo "Adding ARM_CLIENT_ID"
  upload_variable_result=$(curl -s --header "Authorization: Bearer $TFC_TOKEN" --header "Content-Type: application/vnd.api+json" --data @variable.json "https://${address}/api/v2/vars?filter%5Borganization%5D%5Bname%5D=${TFC_ORGANIZATION}&filter%5Bworkspace%5D%5Bname%5D=${workspace}")

  # ARM_SUBSCRIPTION_ID
  sed -e "s/my-organization/$TFC_ORGANIZATION/" -e "s/my-workspace/${workspace}/" -e "s/my-key/arm_subscription_id/" -e "s/my-value/${ARM_SUBSCRIPTION_ID}/" -e "s/my-category/terraform/" -e "s/my-hcl/false/" -e "s/my-sensitive/false/" < variable.template.json  > variable.json
  echo "Adding ARM_SUBSCRIPTION_ID"
  upload_variable_result=$(curl -s --header "Authorization: Bearer $TFC_TOKEN" --header "Content-Type: application/vnd.api+json" --data @variable.json "https://${address}/api/v2/vars?filter%5Borganization%5D%5Bname%5D=${TFC_ORGANIZATION}&filter%5Bworkspace%5D%5Bname%5D=${workspace}")

  # ARM_CLIENT_SECRET
  sed -e "s/my-organization/$TFC_ORGANIZATION/" -e "s/my-workspace/${workspace}/" -e "s/my-key/arm_client_secret/" -e "s/my-value/${ARM_CLIENT_SECRET}/" -e "s/my-category/terraform/" -e "s/my-hcl/false/" -e "s/my-sensitive/false/" < variable.template.json  > variable.json
  echo "Adding ARM_CLIENT_SECRET"
  upload_variable_result=$(curl -s --header "Authorization: Bearer $TFC_TOKEN" --header "Content-Type: application/vnd.api+json" --data @variable.json "https://${address}/api/v2/vars?filter%5Borganization%5D%5Bname%5D=${TFC_ORGANIZATION}&filter%5Bworkspace%5D%5Bname%5D=${workspace}")

  # ARM_TENANT_ID
  sed -e "s/my-organization/$TFC_ORGANIZATION/" -e "s/my-workspace/${workspace}/" -e "s/my-key/arm_tenant_id/" -e "s/my-value/${ARM_TENANT_ID}/" -e "s/my-category/terraform/" -e "s/my-hcl/false/" -e "s/my-sensitive/false/" < variable.template.json  > variable.json
  echo "Adding ARM_TENANT_ID"
  upload_variable_result=$(curl -s --header "Authorization: Bearer $TFC_TOKEN" --header "Content-Type: application/vnd.api+json" --data @variable.json "https://${address}/api/v2/vars?filter%5Borganization%5D%5Bname%5D=${TFC_ORGANIZATION}&filter%5Bworkspace%5D%5Bname%5D=${workspace}")

fi

# Build GCP Project Credentials
if [[ ! -z ${GOOGLE_CREDENTIALS} && ! -z ${GOOGLE_PROJECT} ]]; then
  # GOOGLE_CREDENTIALS
  echo -e "ACTION REQUIRED!! \nGOOGLE_CREDENTIAL Need to be tested.  Key \n char is being interpreted in tfc variable value. \n\n"

  gcp_creds=$(echo ${GOOGLE_CREDENTIALS} | awk '{printf "%s\\n", $0}' | sed "s/\"/\\\\\"/g")
  addKeyVars "gcp_credentials" "${gcp_creds}" true
  upload_variable_result=$(curl -s --header "Authorization: Bearer $TFC_TOKEN" --header "Content-Type: application/vnd.api+json" --data @variable.json "https://${address}/api/v2/vars?filter%5Borganization%5D%5Bname%5D=${TFC_ORGANIZATION}&filter%5Bworkspace%5D%5Bname%5D=${workspace}")

  # GOOGLE_PROJECT
  sed -e "s/my-organization/$TFC_ORGANIZATION/" -e "s/my-workspace/${workspace}/" -e "s/my-key/gcp_project/" -e "s/my-value/${GOOGLE_PROJECT}/" -e "s/my-category/terraform/" -e "s/my-hcl/false/" -e "s/my-sensitive/false/" < variable.template.json  > variable.json
  echo "Adding GOOGLE_PROJECT"
  upload_variable_result=$(curl -s --header "Authorization: Bearer $TFC_TOKEN" --header "Content-Type: application/vnd.api+json" --data @variable.json "https://${address}/api/v2/vars?filter%5Borganization%5D%5Bname%5D=${TFC_ORGANIZATION}&filter%5Bworkspace%5D%5Bname%5D=${workspace}")
fi
# Set Default Region for GCP if Available
if [[ ! -z ${GOOGLE_REGION} && ! -z ${GOOGLE_ZONE} ]]; then
  # GOOGLE_REGION
  sed -e "s/my-organization/$TFC_ORGANIZATION/" -e "s/my-workspace/${workspace}/" -e "s/my-key/gcp_region/" -e "s/my-value/${GOOGLE_REGION}/" -e "s/my-category/terraform/" -e "s/my-hcl/false/" -e "s/my-sensitive/false/" < variable.template.json  > variable.json
  echo "Adding GOOGLE_REGION"
  upload_variable_result=$(curl -s --header "Authorization: Bearer $TFC_TOKEN" --header "Content-Type: application/vnd.api+json" --data @variable.json "https://${address}/api/v2/vars?filter%5Borganization%5D%5Bname%5D=${TFC_ORGANIZATION}&filter%5Bworkspace%5D%5Bname%5D=${workspace}")

  # GOOGLE_ZONE
  sed -e "s/my-organization/$TFC_ORGANIZATION/" -e "s/my-workspace/${workspace}/" -e "s/my-key/gcp_zone/" -e "s/my-value/${GOOGLE_ZONE}/" -e "s/my-category/terraform/" -e "s/my-hcl/false/" -e "s/my-sensitive/false/" < variable.template.json  > variable.json
  echo "Adding GOOGLE_ZONE"
  upload_variable_result=$(curl -s --header "Authorization: Bearer $TFC_TOKEN" --header "Content-Type: application/vnd.api+json" --data @variable.json "https://${address}/api/v2/vars?filter%5Borganization%5D%5Bname%5D=${TFC_ORGANIZATION}&filter%5Bworkspace%5D%5Bname%5D=${workspace}")
fi

# Build AWS Credentials
if [[ ! -z ${AWS_ACCESS_KEY_ID} && ! -z ${AWS_SECRET_ACCESS_KEY} ]]; then
  # AWS_ACCESS_KEY_ID
  sed -e "s/my-organization/$TFC_ORGANIZATION/" -e "s/my-workspace/${workspace}/" -e "s/my-key/aws_access_key_id/" -e "s/my-value/${AWS_ACCESS_KEY_ID}/" -e "s/my-category/terraform/" -e "s/my-hcl/false/" -e "s/my-sensitive/false/" < variable.template.json  > variable.json
  echo "Adding AWS_ACCESS_KEY_ID"
  upload_variable_result=$(curl -s --header "Authorization: Bearer $TFC_TOKEN" --header "Content-Type: application/vnd.api+json" --data @variable.json "https://${address}/api/v2/vars?filter%5Borganization%5D%5Bname%5D=${TFC_ORGANIZATION}&filter%5Bworkspace%5D%5Bname%5D=${workspace}")

  # AWS_SECRET_ACCESS_KEY
  sed -e "s/my-organization/$TFC_ORGANIZATION/" -e "s/my-workspace/${workspace}/" -e "s/my-key/aws_secret_access_key/" -e "s|my-value|${AWS_SECRET_ACCESS_KEY}|" -e "s/my-category/terraform/" -e "s/my-hcl/false/" -e "s/my-sensitive/false/" < variable.template.json  > variable.json
  echo "Adding AWS_SECRET_ACCESS_KEY"
  upload_variable_result=$(curl -s --header "Authorization: Bearer $TFC_TOKEN" --header "Content-Type: application/vnd.api+json" --data @variable.json "https://${address}/api/v2/vars?filter%5Borganization%5D%5Bname%5D=${TFC_ORGANIZATION}&filter%5Bworkspace%5D%5Bname%5D=${workspace}")
fi

# Set Default AWS Region if Available
if [[ ! -z ${AWS_DEFAULT_REGION} ]]; then
  # AWS_DEFAULT_REGION
  sed -e "s/my-organization/$TFC_ORGANIZATION/" -e "s/my-workspace/${workspace}/" -e "s/my-key/aws_default_region/" -e "s/my-value/${AWS_DEFAULT_REGION}/" -e "s/my-category/terraform/" -e "s/my-hcl/false/" -e "s/my-sensitive/false/" < variable.template.json  > variable.json
  echo "Adding AWS_DEFAULT_REGION"
  upload_variable_result=$(curl -s --header "Authorization: Bearer $TFC_TOKEN" --header "Content-Type: application/vnd.api+json" --data @variable.json "https://${address}/api/v2/vars?filter%5Borganization%5D%5Bname%5D=${TFC_ORGANIZATION}&filter%5Bworkspace%5D%5Bname%5D=${workspace}")
fi

# Build HCP Credentials
if [[ ! -z ${HCP_CLIENT_ID} && ! -z ${HCP_CLIENT_SECRET} ]]; then
  # HCP_CLIENT_ID
  sed -e "s/my-organization/$TFC_ORGANIZATION/" -e "s/my-workspace/${workspace}/" -e "s/my-key/HCP_CLIENT_ID/" -e "s/my-value/${HCP_CLIENT_ID}/" -e "s/my-category/terraform/" -e "s/my-hcl/false/" -e "s/my-sensitive/false/" < variable.template.json  > variable.json
  echo "Adding HCP_CLIENT_ID"
  upload_variable_result=$(curl -s --header "Authorization: Bearer $TFC_TOKEN" --header "Content-Type: application/vnd.api+json" --data @variable.json "https://${address}/api/v2/vars?filter%5Borganization%5D%5Bname%5D=${TFC_ORGANIZATION}&filter%5Bworkspace%5D%5Bname%5D=${workspace}")

  # HCP_CLIENT_SECRET
  sed -e "s/my-organization/$TFC_ORGANIZATION/" -e "s/my-workspace/${workspace}/" -e "s/my-key/HCP_CLIENT_SECRET/" -e "s/my-value/${HCP_CLIENT_SECRET}/" -e "s/my-category/terraform/" -e "s/my-hcl/false/" -e "s/my-sensitive/false/" < variable.template.json  > variable.json
  echo "Adding HCP_CLIENT_SECRET"
  upload_variable_result=$(curl -s --header "Authorization: Bearer $TFC_TOKEN" --header "Content-Type: application/vnd.api+json" --data @variable.json "https://${address}/api/v2/vars?filter%5Borganization%5D%5Bname%5D=${TFC_ORGANIZATION}&filter%5Bworkspace%5D%5Bname%5D=${workspace}")
fi

#DEBUG=true
# cleanup
if [[ ! ${DEBUG} ]]; then
  #find ./ -type d -maxdepth 1 -exec rm -rf {} \;
  #find ./ -name "*.tar.gz" -exec rm -rf {} \;
  find ./ -name "*.json.backup" -exec rm -rf {} \;
  rm variable.json workspace.json
fi

echo "Finished"
