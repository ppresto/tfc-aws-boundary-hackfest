# Terraform Cloud Setup
This guide will use the TFC API to bootstrap your initial AWS Admin workspace.  This workspace will be used to manage all the infrastructure provisioned in this guide.  This guide will provision 3 VPC's (HCP Consul with a shared Transit Gateway, EC2 env, and an EKS env).  Each of these environments will have routability to each other through the TGW.  Private networks will only be available to internal resources.  Setup Boundary to proxy to these internal resources (EC2, EKS).

## Pre-requisites
This guide assumes you have some experience with TFC and Github. Before starting the tutorial please complete the following:
* Create TFC Account (free tier)
* Create GitHub Account (free)
* Create HCP Account (free credits)
* Configure TFC to Access your personal Github account
* Acquire AWS credentials with privileges to build all networking and compute resources
* macOS/Linux terminal with bash to initially configure TFC from the CLI.

## Setup your Shell Environment
Export the following TFC, AWS, and HCP environment variables required to bootstrap the TFC administrator workspace. Start setting up our TFC environment variables. Create a personal token or team token if you don't already have one to access your TFC organization from the CLI. You will use this to create your administrative workspace. Copy this to a safe place and then export it into your shells environment.
## TFC
```
export TFC_TOKEN=<token>
```

In TFC go to Settings in the top menu and scroll down to Providers. You should have already set up the GitHub integration. Next, copy the OAUTH_TOKEN_ID value and export it as shown below.
```
export TFC_GIT_OAUTH_TOKEN_ID=<oauth-token-id>
```

In TFC go back to Settings -> General -> Name. This is your organization name. Copy and export this as shown below. The examples In this guide are using organization "presto-projects"
```
export TFC_ORGANIZATION=presto-projects
```

## AWS
Export your AWS target region, key id, and secret access key. The examples in this guide are using region "us-west-2".
```
export AWS_DEFAULT_REGION=us-west-2
export AWS_ACCESS_KEY_ID=<key_id>
export AWS_SECRET_ACCESS_KEY=<secret_key>
```

## SSH
EC2 nodes are provisioned to use your ssh key to allow access for troubleshooting. The following script will create a new SSH Key for this demo environment. 
```
$HOME/.ssh/tfc-hcpc-pipelines.pub
```
This key will not overwrite your existing default keys.

```
source ./tfcb_workspaces/scripts/create-awskeypair.sh
```
Be sure to **source** this script to create the key, AWS keypair, and export the required environment variable AWS_SSH_KEY_NAME needed for the next script.

## HCP Consul
Log into HCP and create a Service Principal so you can configure HCP with Terraform. Copy the HCP client_id and client_secret in a safe place and then update your environment as shown below.  This is mainly required for Consul, and will add Boundary TF shortly.  Set these variables as the TFC creation script will be looking for them.
```
export HCP_CLIENT_ID=<client_id>
export HCP_CLIENT_SECRET=<client_secret>
```

Finally, you are ready to connect to the TFC API to bootstrap the admin workspace which will manage all child workspaces used in this guide.

## Create the TFC Admin Workspace
Edit the addAdmin_workspace.sh script and replace the current GithHub organization ppresto with your ${REPO_ORG} that you set earlier.
```
sed -i".bak" "s/ppresto/${REPO_ORG}/g" tfcb_workspaces/scripts/addAdmin_workspace.sh
```
Review the script and verify the variable git_url points to your GitHub repo. The TFC workspaces need your correct Repo URL to properly setup the VCS driven workflow.
```
cd tfcb_workspaces/scripts
vi addAdmin_workspace.sh
```

### Github Repo URL

```
git_url="https://github.com/${REPO_ORG}/tfc-hcpc-pipelines.git"
```
This shell script is calling the TFC API directly to bootstrap your first workspace into the organization. It copies your local environment variables securely to the Admin workspace which you will use moving forward to manage your organization. Create the admin workspace now.

### Run Creation Script
```
$ ./addAdmin_workspace.sh
```
Login to TFC. Go to your organization and you should see a workspace named admin_tfc_workspaces. Run this workspace to provision and manage the lifecycle of the AWS environment used in this guide.

## HCP
Run the HCP workspace next to create the shared VPC with the Transit Gateway that all other VPC's can attach to for L3/L4 routability.  This VPC includes the Bastion host that is available externally and can route to internal resources.  This host will be setup as a Boundary worker.

## EC2
Run the EC2 workspace to create an internal EC2 host only accessible from the Boundary worker

## EKS
Run the EKS workspace to create EKS.  This is currently setup to be external.  This simplifies the initial creation of the KUBECONFIG for authentication.  When using Boundary for kubectl access the HCP Boundary Server will be used as a worker to route the requests to the EKS cluster.  