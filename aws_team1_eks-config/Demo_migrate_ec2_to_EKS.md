# Demo

## Prep
1. Connect to EKS Cluster
```
#open terminal with iterm shortcut `Shift+Cmd+e` (EKS)
# `Shift+Cmd+v` (VM)
cd aws_eks
dme # Doormat alias to update Terminal with AWS Creds
./awscli_eks_connect.sh
```

2.  Be sure the consul helm chart to install the agent has been deployed.  Then configure the initial defaults and start the web service.
```
cd ${HOME}/Projects/hcp/hcp-consul/aws_eks_consul_agent/templates/fs-ns-tp
kubectl apply -f init-consul-config/
kubectl apply -f web.yaml
```

3. web will expect the api service to be running on the EC2 instances.  Lets check that these are running in the Consul UI.  If not ssh to the hosts and start the api fake-service.
```
ssh ubuntu@
sudo su -
cd /opt/consul/fake-service
./start.sh
```
4. Build web -> api Intention (can do manually during demo to show intentions)
4. Open Fake-service URL.
```
echo "http://$(kubectl get svc consul-ingress-gateway -n consul -o json | jq -r '.status.loadBalancer.ingress[].hostname'):8080/ui"
```


## Review Current Environment
* Walk through [TFCB Workspaces](https://app.terraform.io/app/presto-projects/workspaces)
* HCP, AWS VPC/TG, EKS cluster (Consul, and services)
* [Show Consul Dashboard](https://hcpc-cluster-presto.consul.328306de-41b8-43a7-9c38-ca8d89d06b07.aws.hashicorp.cloud/ui/~api-ns/hcpc-cluster-presto/services/api/intentions) (consul + web + api services)
  * Services -> api  - vm,v1 tags, Intentions

## Fake-Service App
Show Terminal sessions to EC2 to see api svc.  
Show current K8s cluster pods to see web.
```
kubectl get pods -A -l service=fake-service
```
* Show Fake Service URL - LB across EC2 (onprem/legacy/brownfield)


## Deploy api-v2 : Migration to EKS
This will deploy api-v2 pod, and apply traffic rules to route 100% to api-v1.
```
kubectl apply -f ./release-v2
sleep 2
kubectl get pods -l service=fake-service
```
* Review Fake Service URL
* Review api service routing in Consul UI.

Phase traffic over to api-v2.
* Update ./release-v2/traffic-mgmt.yaml (split 20/50/100)
```
kubectl apply -f release-v2/traffic-mgmt.yaml
```

## Deploy api-v3 : Show integration testing
This will deploy api-v3 pod, and apply traffic rules to route baggage header "version=2" to v3.
```
kubectl apply -f ./release-v3
sleep 1
kubectl get pods -l service=fake-service
```
* Review Fake Service URL
* Review api service routing in Consul UI.

Enable ModHeaders in Chrome.  Add baggage header with value: 'version=2'
Reload Fake Service URL to show traffic routing by header.

## Clean up
```
cd $HOME/Projects/hcp/hcp-consul/aws_eks_apps/templates/fs-ns-tp
kubectl delete -f release-v3
kubectl delete -f release-v2
kubectl delete -f web.yaml
kubectl delete -f init-consul-config/

source scripts/setConsulEnv.sh <CONSUL_TOKEN>
consul namespace delete api-ns
consul namespace delete payments-ns
consul namespace delete currency-ns
```

## Troubleshooting
Read consul configuration settings from the CLI
```
source scripts/setConsulEnv.sh <CONSUL_TOKEN>
consul config read -kind service-defaults -name api
consul config read -kind service-router -name api
consul config read -kind service-resolver -name api
consul config read -kind service-splitter -name api
consul config read -kind service-intentions -name api
```
List and Delete work the same as Read.
Write examples are in EC2:/opt/consul/fake-service/start.sh

Read consul config from CRD
```
kubectl describe servicedefaults api
kubectl describe servicerouters api
kubectl describe serviceresolvers api
kubectl describe servicesplitters api
kubectl describe serviceintentions api
```