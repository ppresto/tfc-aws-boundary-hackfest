<!-- TOC -->

- [Boundary Hackfest](#boundary-hackfest)
  - [EKS](#eks)
    - [UI / CLI Setup](#ui--cli-setup)
      - [Install the Boundary CLI.](#install-the-boundary-cli)
      - [Login](#login)
      - [Create PROJECT, HOST_CATALOG, HOST, HOST_SET, and TARGET](#create-project-host_catalog-host-host_set-and-target)
      - [Create HOST_CATALOG, HOST, HOST_SET, and TARGET](#create-host_catalog-host-host_set-and-target)
      - [Create Target](#create-target)
    - [Access the EKS cluster with kubectl.](#access-the-eks-cluster-with-kubectl)
      - [Get host catalog id and export](#get-host-catalog-id-and-export)
      - [Verify Env](#verify-env)
      - [Connect to EKS Cluster with boundary kube helper](#connect-to-eks-cluster-with-boundary-kube-helper)
  - [EC2 Boundary Worker](#ec2-boundary-worker)
    - [SSH to EC2 Instance for initial setup](#ssh-to-ec2-instance-for-initial-setup)
      - [Install Boundary](#install-boundary)
      - [Start server to generate Auth Token](#start-server-to-generate-auth-token)
      - [Open NEW local Terminal Window](#open-new-local-terminal-window)
      - [Update description](#update-description)
      - [Update worker tags with targert_id](#update-worker-tags-with-targert_id)
    - [Start the Boundary Worker again](#start-the-boundary-worker-again)
    - [Connect to internal EC2 instance on private network](#connect-to-internal-ec2-instance-on-private-network)

<!-- /TOC -->
# Boundary Hackfest

Use cases:
* EKS: Setup HCP Boundary to allow local kubectl commands to EKS Cluster
* EC Boundary Worker: Setup Boundary worker node to SSH to internal AWS EC2 hosts

EKS - Questions
* Do you have to use a local KUBECONFIG to authenticate to EKS when using Boundary?
* Can Boundary workers be used at the EKS cluster level for better remote access and RBAC to pods then K8s?  Any examples?

EC Boundary Worker - Questions
* How can you automate boostrapping a new Boundary worker using TF when it needs to generate the key?
* Can you leverage IAM roles on the worker to authenticate to other AWS resources like EKS pods?

## EKS
Use HCP Boundary to access EKS Cluster locally with kubectl.  The HCP Boundary cluster runs as a worker too so it can facilitate proxying access.  Boundary will proxy requests to the EKS cluster but does not support authentication so use KUBECONFIG.

PreReq:
* Create AWS VPC with an EKS Cluster
* Create Transit GW or Peering from EKS Cluster to HCP
* Setup local KUBECONFIG required for EKS authentication

Use TFC to initially setup the PreReq's.  Review the README for detailed steps.
`./tfcb_workspaces/README.md`

Once the required AWS infrastructure above is in place proceed top the Boundary setup.

### UI / CLI Setup
Sign into HCP and create the Boundary cluster.  This will create the ORG_ID, default BOUNDARY_ADMIN username, Password, and AUTH_ID.  Save this information to setup your local shell to use the Boundary CLI.

```
export BOUNDARY_ADMIN=admin
export ORG_ID=o_Hhxr7HASd2
export AUTH_ID=ampw_H4eruw7DNY
export BOUNDARY_ADDR=https://a757c9c0-d7ab-435c-8998-2ae96fac9ada.boundary.hashicorp.cloud
```

#### Install the Boundary CLI.  
```
brew install hashicorp/tap/boundary
```

Update the setEnv.sh with the correct ENV values and source this file.
```
source setENv.sh
```


#### Login
boundary authenticate password \
-auth-method-id=$AUTH_ID \
-login-name=$BOUNDARY_ADMIN

#### Create PROJECT, HOST_CATALOG, HOST, HOST_SET, and TARGET

Create the Project and scope first.  A project can have roles associated to it for various access, and can contain many different catalogs of hosts.

```
export PROJECT_ID=$(boundary scopes create \
   -scope-id=$ORG_ID \
   -name=team1-eks \
   -description="team1 - EKS" \
   -format json | jq -r '.item | .id')
```

#### Create HOST_CATALOG, HOST, HOST_SET, and TARGET

Create one Host Catalog in the Project that will include a host-set of one host (the EKS cluster).
```
export HOST_CATALOG_ID=$(boundary host-catalogs create static \
   -scope-id=$PROJECT_ID \
   -name=team1-usw2 \
   -description="team1 usw2 catalog" \
   -format json | jq -r '.item | .id')
```

Create the HOST_ID.  This will contain the EKS endpoint and add it to the HOST_CATALOG.
```
export HOST_ID=$(boundary hosts create static \
   -name=eks1 \
   -description="eks1" \
   -address=$EKS_ENDPOINT \
   -host-catalog-id=$HOST_CATALOG_ID \
   -format json | jq -r '.item | .id')
```

The host catalog uses a host-set to organize groups of multiple hosts.  
```
export HOST_SET_ID=$(boundary host-sets create static \
   -name="eks1-host-set" \
   -description="EKS1 host set" \
   -host-catalog-id=$HOST_CATALOG_ID \
   -format json | jq -r '.item | .id')
```

Add the host to the host_set
```
boundary host-sets add-hosts -id=$HOST_SET_ID -host=$HOST_ID
```
#### Create Target
Finally create a target for the host-set and define the port of the hosts you want to proxy to.
```
export TARGET_ID=$(boundary targets create tcp \
   -name="eks1-target" \
   -description="eks1 target" \
   -default-port=443 \
   -scope-id=$PROJECT_ID \
   -session-connection-limit="-1" \
   -format json | jq -r '.item | .id')
```

Add the host-set to the target
```
boundary targets add-host-sets -id=$TARGET_ID -host-set=$HOST_SET_ID
```

### Access the EKS cluster with kubectl.
PreReq:  Create EKS cluster with access to HCP Boundary

Set the EKS endpoint environment variable.
```
# Get EC2 external IP, user, and private key
export EKS_ENDPOINT="FFDD07B33C7C6610DD2987C613E2417A.sk1.us-west-2.eks.amazonaws.com"
```

#### Get host catalog id and export
```
boundary host-catalogs list -scope-id $PROJECT_ID
export HOST_CATALOG_ID="<input-catalog-id>"
```

#### Verify Env
```
echo "EKS_USER=$EKS_USER"; 
echo "EKS_CERT=$EKS_CERT"; 
echo "PROJECT_ID=$PROJECT_ID"; 
echo "HOST_CATALOG_ID=$HOST_CATALOG_ID"; 
echo "HOST_ID=$HOST_ID"; 
echo "HOST_SET_ID=$HOST_SET_ID"; 
echo "TARGET_ID=$TARGET_ID"
```

#### Connect to EKS Cluster with boundary kube helper
```
boundary connect kube -target-id=$TARGET_ID -host-id=$HOST_ID -- get nodes"

boundary connect kube -target-id=$TARGET_ID -host-id=$HOST_ID -scheme https -- cluster-info --context arn:aws:eks:us-west-2:164308961573:cluster/presto-aws-team1-eks
```

## EC2 Boundary Worker
PreReqs:
* VPC with public and private networks
* Boundary worker EC2 instance in public subnet that has an external IP,
* The Boundary worker needs routes to the private network to target hosts.
* Security Group - Clients need external TCP access to Boundary worker on port 9202 for proxy.
* Create EC2 instance in private network that has no public access

Use TFC to initially setup the PreReq's.  Review the README for detailed steps.
`./tfcb_workspaces/README.md`

Once the required AWS infrastructure above is in place proceed top the Boundary setup.

### SSH to EC2 Instance for initial setup

#### Install Boundary
```
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add - ;\
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" ;\
sudo apt-get update && sudo apt-get install boundary=0.10.5-1

boundary version
# apt-cache policy boundary  # Find boundary versions available

mkdir /home/ubuntu/boundary/
touch /home/ubuntu/boundary/pki-worker.hcl
```
* Copy/Paste templates/pki-worker.hcl to /home/ubuntu/boundary/pki-worker.hcl
* Modify pki-worker.hcl with boundary cluster_id and host ext ip

#### Start server to generate Auth Token
This will generate the `Worker AUth Registration Request Token`.  Once you see this in the output exit the server and copy the token.  This is a complex workflow to automat.  How can you automate the provisioning of the PKI worker when it needs to generate the init key, and pass this to the Boundary server for bootstapping.
```
sudo boundary server -config="/home/ubuntu/boundary/pki-worker.hcl"
```

#### Open NEW local Terminal Window

Update the setEnv.sh with the correct ENV values and source this file.
```
source setENv.sh
```

Login
```
boundary authenticate password \
-auth-method-id=$AUTH_ID \
-login-name=$BOUNDARY_ADMIN
```

Input the worker token you copied before, and get the worker-id after it connects.
```
export WORKER_TOKEN=<Worker Auth Registration Request Token from Worker>

boundary workers create worker-id -worker-generated-auth-token=$WORKER_TOKEN
boundary workers read  # get id of PKI worker
boundary workers read -id <id>
```

#### Update description
boundary workers update -id=w_hV7XGrl6Vc -name="pki-worker1" -description="my first self-managed worker"

#### Update worker tags with targert_id
boundary targets update tcp -id $TARGET_ID -worker-filter='"dev-worker" in "/tags/type"'

### Start the Boundary Worker again
```
sudo boundary server -config="/home/ubuntu/boundary/pki-worker.hcl"
```

### Connect to internal EC2 instance on private network
```
boundary connect ssh -target-id=ttcp_A7BWTqUb5c -host-id=hst_o3ajZs2QvC -- -l ubuntu -i /Users/patrickpresto/.ssh/tfc-hcpc-pipelines
```
