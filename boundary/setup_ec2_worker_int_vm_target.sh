#!/bin/bash

source ./setEnv.sh

# Get EC2 external IP, user, and private key
export UBUNTU_IP=10.20.1.29
export UBUNTU_USER=ubuntu 
export UBUNTU_KEY="${HOME}/.ssh/tfc-hcpc-pipelines"


# Login
boundary authenticate password \
-auth-method-id=$AUTH_ID \
-login-name=$BOUNDARY_ADMIN

# Create Scope
export PROJECT_ID=$(boundary scopes create \
   -scope-id=$ORG_ID \
   -name=team1-int-ec2 \
   -description="team1-internal" \
   -format json | jq -r '.item | .id')

export HOST_CATALOG_ID=$(boundary host-catalogs create static \
   -scope-id=$PROJECT_ID \
   -name=team1-internal-catalog \
   -description="My first catalog" \
   -format json | jq -r '.item | .id')

export HOST_ID=$(boundary hosts create static \
   -name=ubuntu \
   -description="single host" \
   -address=$UBUNTU_IP \
   -host-catalog-id=$HOST_CATALOG_ID \
   -format json | jq -r '.item | .id')

export HOST_SET_ID=$(boundary host-sets create static \
   -name="ubuntu-host-set" \
   -description="Ubuntu host set" \
   -host-catalog-id=$HOST_CATALOG_ID \
   -format json | jq -r '.item | .id')

# Add host to host_set
boundary host-sets add-hosts -id=$HOST_SET_ID -host=$HOST_ID

export TARGET_ID=$(boundary targets create tcp \
   -name="ubuntu-target" \
   -description="ubuntu target" \
   -default-port=22 \
   -scope-id=$PROJECT_ID \
   -session-connection-limit="-1" \
   -format json | jq -r '.item | .id')

# Add host_set to target
boundary targets add-host-sets -id=$TARGET_ID -host-set=$HOST_SET_ID

# output ENV Variables
echo "UBUNTU_USER=$UBUNTU_USER"; echo "UBUNTU_KEY=$UBUNTU_KEY"; echo "PROJECT_ID=$PROJECT_ID"; echo "HOST_CATALOG_ID=$HOST_CATALOG_ID"; echo "HOST_ID=$HOST_ID"; echo "HOST_SET_ID=$HOST_SET_ID"; echo "TARGET_ID=$TARGET_ID"

# get host catalog id
boundary host-catalogs list -scope-id $PROJECT_ID

# Connect to target
echo "boundary connect ssh -target-id=$TARGET_ID -host-id=$HOST_ID -- -l $UBUNTU_USER -i $UBUNTU_KEY"

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

