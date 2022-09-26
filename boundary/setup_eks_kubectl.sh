#!/bin/bash

source ./setEnv.sh

# Get EC2 external IP, user, and private key
export EKS_ENDPOINT="FFDD07B33C7C6610DD2987C613E2417A.sk1.us-west-2.eks.amazonaws.com"
export EKS_USER="arn:aws:eks:us-west-2:164308961573:cluster/presto-aws-team1-eks" 
export EKS_CERT="LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM1ekNDQWMrZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJeU1Ea3lNakU0TVRRMU1sb1hEVE15TURreE9URTRNVFExTWxvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTHMzCmdSRkpEYmJxVEh1SFl0WFVjY0RGTXhTalJacGhDRVQ3aHhBbk5ESzZHdkNhMWFTUFNjcGVmZ3owYit2TXR6ZTAKemkrY3FvSkgxem5XZjBXWWcyNk9xV2tFWVVFSndIeEVDSk1OUFdNTGNrLy95dW5GM29odElBOHN6cE9zQ3ZCWQpTcEk5RThpUTlRRFpZN1pMeEZZN1BhdHY0ZUdaYlNHU2hRckthZUVONERNNEJmcVNUaFFkQk1uTzRhNUhpci9wCkpLUlB6RTA5ZXR0UUJZTWRUb1FPWVhLa1NtSEdPeUVGb0duTnczVzFhdnJuQXh6NkwxUTBCNjYyOGUydk05S3kKUXRGTzl4REE1ME9NSmdEM2tiQmxzRWZKdTRUZkExK0V1WU5abEYxWmRUdm9Xc0hBd3BoSjNmNVVRTUdQamVlcgpMMTlodlVtWU4yQVh1STJEbnFNQ0F3RUFBYU5DTUVBd0RnWURWUjBQQVFIL0JBUURBZ0trTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0hRWURWUjBPQkJZRUZIOG1TczFuYkpVeGlRRG1EWWR1M2dKNHRFdmxNQTBHQ1NxR1NJYjMKRFFFQkN3VUFBNElCQVFDMG5BTUJDUkV0RWIwaUh0aTNZME82cUVxRXJtcmIwYjllYUR2US9kbFZjWC9FZk1WWgo3eU5IQTVFZ0o2MHBWZkVYK0ZyZWVBVFVEQ3FUaXlkbFhCTGpvTTNlV2ZrNDFrUW15SmdJTm8vNDVsMUNmdXNlCm1LMGx4WCt5UVNTVVZmVmJicTBEY2VPdC9GTW0zTVo3akxWcUM4SU1PYmMzdFlRc0RDMXpIWEI2dytWL1h5czUKQ01SRVJya1kzcldNRXFGNHhnOUVDOUV6WDJvVEhuMU52UndhZXpCYkEwamRXM1p4dUl1SXFsblduU0Rvb2lyWAptZGsyZVgvb0JoS1h2S2FyZjNYQUkySkJ6cEJBWWxkamk4eWorYTA0RDhIVUNSMDV1WlBwUmtsdHEyVWt2SjhLCk5OMklQWW14VlRwbFJuRUZpQXpyaTIxUEdWT0xRWnVUdnJPcgotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg=="


# Login
boundary authenticate password \
-auth-method-id=$AUTH_ID \
-login-name=$BOUNDARY_ADMIN

# Create Scope
export PROJECT_ID=$(boundary scopes create \
   -scope-id=$ORG_ID \
   -name=team1-eks \
   -description="team1 - EKS" \
   -format json | jq -r '.item | .id')

export HOST_CATALOG_ID=$(boundary host-catalogs create static \
   -scope-id=$PROJECT_ID \
   -name=team1-usw2 \
   -description="team1 usw2 catalog" \
   -format json | jq -r '.item | .id')

export HOST_ID=$(boundary hosts create static \
   -name=eks1 \
   -description="eks1" \
   -address=$EKS_ENDPOINT \
   -host-catalog-id=$HOST_CATALOG_ID \
   -format json | jq -r '.item | .id')

export HOST_SET_ID=$(boundary host-sets create static \
   -name="eks1-host-set" \
   -description="EKS1 host set" \
   -host-catalog-id=$HOST_CATALOG_ID \
   -format json | jq -r '.item | .id')

# Add host to host_set
boundary host-sets add-hosts -id=$HOST_SET_ID -host=$HOST_ID

export TARGET_ID=$(boundary targets create tcp \
   -name="eks1-target" \
   -description="eks1 target" \
   -default-port=443 \
   -scope-id=$PROJECT_ID \
   -session-connection-limit="-1" \
   -format json | jq -r '.item | .id')

# Add host_set to target
boundary targets add-host-sets -id=$TARGET_ID -host-set=$HOST_SET_ID

# output ENV Variables
echo "EKS_USER=$EKS_USER"; echo "EKS_CERT=$EKS_CERT"; echo "PROJECT_ID=$PROJECT_ID"; echo "HOST_CATALOG_ID=$HOST_CATALOG_ID"; echo "HOST_ID=$HOST_ID"; echo "HOST_SET_ID=$HOST_SET_ID"; echo "TARGET_ID=$TARGET_ID"

# get host catalog id
boundary host-catalogs list -scope-id $PROJECT_ID

# Connect to target
echo "boundary connect kube -target-id=$TARGET_ID -host-id=$HOST_ID -- get nodes"
#Team1 Context
echo "boundary connect kube -target-id=$TARGET_ID -host-id=$HOST_ID -scheme https -- cluster-info --context arn:aws:eks:us-west-2:164308961573:cluster/presto-aws-team1-eks"

# Create static user passwd
# https://learn.hashicorp.com/tutorials/boundary/hcp-getting-started-credentials?in=boundary/hcp-getting-started


# MacOS - Install Boundary desktop and connect
# brew tap hashicorp/tap
# brew install hashicorp-boundary-desktop

# CMD+spacebar , 'boundary.app' , ENTER

echo $BOUNDARY_ADDR
# Login with BOUNDARY_ADDR and user/pass
# Go to tab: Targets -> Connect
# Copy proxy details, or lookup in Session tab
# ssh -p 56733 ubuntu@localhost -i /Users/patrickpresto/.ssh/tfc-hcpc-pipelines

