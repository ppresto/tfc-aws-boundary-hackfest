#!/bin/bash

source ./setEnv.sh

# Install Boundary
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add - ;\
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" ;\
sudo apt-get update && sudo apt-get install boundary=0.10.5-1

boundary version
# apt-cache policy boundary  # Find boundary versions available

mkdir /home/ubuntu/boundary/
touch /home/ubuntu/boundary/pki-worker.hcl
# Modify pki-worker.hcl with boundary cluster_id and host ext ip

# Start server to generate Auth Token
sudo boundary server -config="/home/ubuntu/boundary/pki-worker.hcl"

# Stop Server.
# Copy Worker Auth Registration Request Token from Worker
# Open NEW local Terminal Window
  # Login - boundary authenticate password -auth-method-id=$AUTH_ID -login-name=$BOUNDARY_ADMIN 
  # export WORKER_TOKEN=<Worker Auth Registration Request Token from Worker>
  boundary workers create worker-led -worker-generated-auth-token=$WORKER_TOKEN
  boundary workers read  # get id of PKI worker
  boundary workers read -id <id>
  # Update description
  boundary workers update -id=w_hV7XGrl6Vc -name="pki-worker1" -description="my first self-managed worker"

  # Update worker tags with targert_id
  boundary targets update tcp -id $TARGET_ID -worker-filter='"dev-worker" in "/tags/type"'