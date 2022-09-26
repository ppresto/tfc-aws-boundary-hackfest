# TFE Automation Script
`./scripts/addAdmin_workspace.sh` creates a workspace that is integrated with a GitHub repo.  This script creates your initial ADMIN Workspace which holds global vars including sensitive terraform/env variables and should be locked down to owners only.  This workspace will be used to securely create child workspaces configured with sensitive credentials already encrypted as write only values.  This model can allow other teams/users access to a specific child workspace that has a webhook to a specifc github repo/branch and will automatically run plans for PR's, and apply any commits.  This enables other users and teams to get up and running quickly, and manage day 2 ops for their own infra without ever having access to the AWS credentials used to provision.

## Introduction
This script uses curl to interact with Terraform Enterprise via the Terraform Enterprise REST API. The same APIs can be used from Jenkins or other solutions to incorporate a Terraform Enterprise API driven workflow into your CI/CD pipeline.

Add your sensitive Cloud credentials by sourcing them into your shell as local environment variables.  If using OSS you are probably already doing this.  The default script will look for the default HCP, AWS, GCP, and Azure ENV variables during runtime. Here are a list of shell environment variables the script will look for.


Required
```
OAUTH_TOKEN_ID <setup github oauth and export ID here>
ATLAS_TOKEN <Terraform Enterprise Team Token>
TFC_ORGANIZATION <your github org name>
```

Required for this tutorial.
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_DEFAULT_REGION
HCP_CLIENT_ID
HCP_CLIENT_SECRET
SSH_KEY_NAME
```

Others
```
ARM_CLIENT_ID
ARM_SUBSCRIPTION_ID
ARM_CLIENT_SECRET
ARM_TENANT_ID
GOOGLE_CREDENTIAL
GOOGLE_PROJECT
GOOGLE_REGION
GOOGLE_ZONE
```

You will see a couple `template.json` files in this ./scripts directory.  The script will update these templates and using curl will call the TFCB API to create your workspace and any defined variables.
* You can uncomment the DEBUG variable at the bottom of the script if you want to review the files that get created and used in the API calls for troubleshooting.

## Setup
1. Sign up for a TFC account, login, and create your organization
2. [Setup VCS integration](https://www.terraform.io/docs/cloud/vcs/github.html) with your Github account/org
3. Generate a [team token](https://www.terraform.io/docs/enterprise/users-teams-organizations/service-accounts.html#team-service-accounts) for the owners team in your organization.  In the Terraform Enterprise UI select your organization settings, then Teams, then owners, and then click the Generate button and save the token that is displayed.  Set the env variable ATLAS_TOKEN=<team token>.
4. Make sure [python](https://www.python.org/downloads/) is installed on your machine and in your path since the script uses python to parse JSON documents returned by the Terraform Enterprise REST API.  You can updated the script to use jq if you want.
5. Build your first workspace using the API script in this repo.

To use the TFCB API script you need to update it for your environment.  
```
vi ./tfcb_workspaces/scripts/addAdmin_workspace.sh
```
Customize the following variables in `./addAdmin_workspace.sh`:
```
## The default is using the TFCB address. Update if using TFE onprem.
address="app.terraform.io"

## Update the organization with your TFCB organization name
organization="<my_org>"

## Set this github URL to your forked version of this repo
git_url="https://github.com/ppresto/hcpc-vpc-ec2-eks.git"

## Admin Workspace Name
workspace="admin-tfc-workspaces"

## Github repo path to use for managing your workspaces with IaC
WORKSPACE_DIR="tfcb_workspaces"
BRANCH="main"

## Select Terraform Version
TF_VERSION="1.1.4"
```
### Export your AWS credentials to have them managed by the TFCB admin workspace:
```
export AWS_SECRET_ACCESS_KEY="key_value_here"
export AWS_ACCESS_KEY_ID="key_id_here"
```

#### Hashicorp SE's use instruqt for short lived AWS Credentials.
Hashicorp SE's can use this instruqt sandbox terminal to quickly source short lived AWS Credentials into their environment.  This can help prevent running into vpc/tgw limits.  Click here to start the [Instruqt sandbox workshop](https://play.instruqt.com/hashicorp/tracks/fra-ssn-enablement)
```
echo "export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}\nexport AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}"
```

* Cut and paste the output into your local terminal session. 
* Set your AWS_DEFAULT_REGION.
```
#cut/paste output from instruqt environment into your terminal session

export AWS_DEFAULT_REGION="us-west-2"
```

If you want to inject credentials into TFC with doormat, vault, or another workflow you can easily disable this by commenting out the env_variables_sec var in each workspace file (./tfcb_workspaces/<workspace-name>.tf).
```
env_variables_sec = {
#"AWS_ACCESS_KEY_ID" = var.aws_access_key_id
#"AWS_SECRET_ACCESS_KEY" = var.aws_secret_access_key
}
```
Note: There are many different ways to manage creds in TFCB depending on your security requirements.  These creds will be encrypted in each child workspace.  They will be clear text in the

### Create AWS keypair
EC2 and EKS nodes are provisioned to use your ssh key to allow direct access.  You may already have an existing ssh key you can use in AWS.  Check for an existing default named key in your home directory
```
ls -al $HOME/.ssh/id_rsa*
```
If you see 2 files (id_rsa_pub, id_rsa) then there is no need to create a new key.

If you have no key, create one with ssh-keygen
```
ssh-keygen -t rsa
```

Copy your local key into AWS with the following script and set the SSH_KEY_NAME environment variable used by ./addAdmin_workspace.sh.
```
source ./push-local-sshkeypair-to-aws.sh
```
Edit the script to define your key location, keypair name, and target region.  By default this script will copy $HOME/.ssh/id_rsa.pub, to `my-aws-keypair-###`, across all available AWS regions.

Verify 
1. Pre-Check
Verify you have the Required environment variables set (OAUTH_TOKEN_ID, ATLAS_TOKEN, organization, AWS, HCP, and SSH)
```
env
```
There are many different ways to manage credentials in your TFC workspace. One option can be to use this Admin workspace.  Source your Cloud credentials into your shell env to securely copy them over HTTPS into your admin workspace.  When building child workspaces you can now reference these variables from the admin workspace and have them populated into the child workspace as write only variables.  This design allows only the Admin to see the secrets while all child workspaces inherit them as encrypted variables used for provisioning access.

2. Run the script
```
./addAdmin_workspace.sh
```
You should now have your ADMIN workspace created in TFCB and be ready to provision child workspaces with standard configurations and securely add encrypted sensitive variables too.