# OpenTracing with Jaeger and fake-service

## Deploy fake-service
use kubectl to manually deploy consul servicedefaults, intentions, and fake-services.
```
cd /Users/patrickpresto/Projects/hcp/hcp-consul/aws_eks_apps/templates/fs-tp
kubectl apply -f .
kubectl apply -f ./init-consul-config
kubectl get pods -A -l service=fake-service
```
### Get Consul IngressGW URL
If Consul is installed in K8s namespace add it like: `-n consul`
```
#list ports (default 8080)
kubectl get svc consul-ingress-gateway -o json | jq -r '.spec.ports[].port'

# output URL
echo "http://$(kubectl get svc consul-ingress-gateway -o json | jq -r '.status.loadBalancer.ingress[].hostname'):8080"
```

## Run Jaeger
Its recommended to use the Jaeger operator in K8s, but you can also generate the needed yaml from the jaeger-operator's `simplest` example for a quick dev env.  This example will generate the yaml for the latest all-in-one version so backup existing configs.
```
curl https://raw.githubusercontent.com/jaegertracing/jaeger-operator/main/examples/simplest.yaml | docker run -i --rm jaegertracing/jaeger-operator:master generate > jaeger-all-in-one.yaml
```
Once deployed you will have a few services and the simplest pod runnning.  This is Jaeger.

To view the UI use kubernetes port forwarding.
```
export POD_NAME=$(kubectl get pods -l app.kubernetes.io/instance=simplest -o name)
kubectl port-forward ${POD_NAME} 16686:16686
```

### Review Jaeger Trace examples

## Setup EC2 Ubuntu Instance
Install Envoy
```
curl https://func-e.io/install.sh | sudo bash -s -- -b /usr/local/bin
func-e versions -all
func-e use 1.20.2
sudo cp /home/ubuntu/.func-e/versions/1.20.2/bin/envoy /usr/local/bin
envoy --version
```

Install Docker
```
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Test Installation
sudo docker run hello-world
docker compose version

# install loki log driver
sudo docker plugin install grafana/loki-docker-driver:latest --alias loki --grant-all-permissions
```
To install specific versions of docker...
```
#search versions (2nd column)
apt-cache madison docker-ce

#install specific version
sudo apt-get install docker-ce=<VERSION_STRING> docker-ce-cli=<VERSION_STRING> containerd.io docker-compose-plugin
```
## Troubleshooting

### SSH
The TF is leveraging your AWS Key Pair for the Bastion/EC2 and EKS nodes.  Use `Agent Forwarding` to ssh to your nodes.  Locally in your terminal find your key and setup ssh.
```
ssh-add -L  # Find SSH Keys added
ssh-add ${HOME}/.ssh/my-dev-key.pem  # If you dont have any keys then add your key being used in TF.
ssh -A ubuntu@<BASTION_IP>>  # pass your key in memory to the ubuntu Bastion Host you ssh to.
ssh -A ec2_user@<K8S_NODE_IP> # Use your key to access the K8s Node
```
### Helm
Manually install consul using Helm.  The test.yaml can be created from Terraform Output.
```
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install consul hashicorp/consul --create-namespace --namespace consul --version 0.33.0 --set global.image="hashicorp/consul-enterprise:1.11.0-ent" --values ./helm/test.yaml
helm status consul
```

### Kubernetes

For proxy global default changes to take affect restart envoy sidecars with rolling deployment.
```
for i in  $(kubectl get deployments -l service=fake-service -o name); do kubectl rollout restart $i; done
```

### Kubernetes EKS DNS
Get DNS services (consul and coredns), start busybox, and use nslookup
```
consuldnsIP=$(kubectl -n consul get svc consul-dns -o json | jq -r '.spec.clusterIP')
corednsIP=$(kubectl -n kube-system get svc kube-dns -o json | jq -r '.spec.clusterIP')
kubectl run busybox --restart=Never --image=busybox:1.28 -- sleep 3600
kubectl exec busybox -- nslookup kubernetes $corednsIP
```

Test coredns config
```
kubectl run busybox --restart=Never --image=busybox:1.28 -- sleep 3600
kubectl exec busybox -- nslookup kubernetes $corednsIP
```
Test consul config
```
kubectl exec busybox -- nslookup web.default
kubectl exec busybox -- nslookup web.service.consul $consuldnsIP
kubectl exec busybox -- nslookup web.service.consul
kubectl exec busybox -- nslookup web
kubectl exec busybox -- nslookup api.service.consul
```

References:
https://aws.amazon.com/premiumsupport/knowledge-center/eks-dns-failure/
#### Terminate stuck namespace

Start proxy on localhost:8001
```
kubectl proxy
```

Use k8s API to delete namespace
```
cat <<EOF | curl -X PUT \
  localhost:8001/api/v1/namespaces/currency-ns/finalize \
  -H "Content-Type: application/json" \
  --data-binary @-
{
  "kind": "Namespace",
  "apiVersion": "v1",
  "metadata": {
    "name": "currency-ns"
  },
  "spec": {
    "finalizers": null
  }
}
EOF
```

Find finalizers in "spec"
```
kubectl get namespace api -o json > temp.json
```

```
"spec": {
        "finalizers": []
    }
```
#### Terminate stuck objects
Examples to Fix defaults, intentions, and ingressgateways that wont delete
```
kubectl patch servicedefaults.consul.hashicorp.com api -n api-ns --type merge --patch '{"metadata":{"finalizers":[]}}'
kubectl patch servicedefaults.consul.hashicorp.com web --type merge --patch '{"metadata":{"finalizers":[]}}'

kubectl patch ingressgateway.consul.hashicorp.com ingress-gateway --type merge --patch '{"metadata":{"finalizers":[]}}'

kubectl patch serviceintentions.consul.hashicorp.com web --type merge --patch '{"metadata":{"finalizers":[]}}'
```

### Envoy
Get Envoy Proxy Information
```
kubectl exec -it web-7c4f6d77d8-gqs2p -c envoy-sidecar -- wget -qO- http://localhost:19000/clusters
kubectl exec -it web-7c4f6d77d8-gqs2p -c envoy-sidecar -- wget -qO- http://localhost:19000/config_dump
```

NetCat - Verify IP:Port connectivity from EKS Pod
```
kubectl exec -it web-7c4f6d77d8-gqs2p -c web -- nc -zv 10.20.11.138 21000
kubectl exec -it web-7c4f6d77d8-gqs2p -c envoy-sidecar -- nc -zv 10.20.11.138 20000
```

### Consul

Service DNS lookups
```
web.service.consul
web.ingress.consul
api.virtual.consul
api.virtual.api-ns.ns.default.ap.hcpc-cluster-presto.dc.consul
```

Deregister Node to remove consul-sync k8s services from HCP.
```
curl \
    --header "X-Consul-Token: ${CONSUL_HTTP_TOKEN}" \
    --request PUT \
    --data '{"Datacenter": "hcpc-cluster-presto","Node": "k8s-sync"}' \
    https://hcpc-cluster-presto.consul.328306de-41b8-43a7-9c38-ca8d89d06b07.aws.hashicorp.cloud//v1/catalog/deregister
```