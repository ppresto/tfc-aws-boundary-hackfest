#!/bin/bash

export CONSUL_HTTP_ADDR=https://hcpc-cluster-presto.consul.328306de-41b8-43a7-9c38-ca8d89d06b07.aws.hashicorp.cloud
export CONSUL_HTTP_TOKEN="${1}"

# Connect CA is 3 day default in Envoy
# curl -s ${CONSUL_HTTP_ADDR}/v1/connect/ca/roots | jq -r '.Roots[0].RootCert' | openssl x509 -text -noout

# Review Consul ingress gateway

# kubectl exec $(kubectl get pods -n consul -l ingress-gateway-name=consul-ingress-gateway -o name) -n consul -c ingress-gateway -- wget -qO- 127.0.0.1:19000/clusters

# kubectl exec $(kubectl get pods -n consul -l ingress-gateway-name=consul-ingress-gateway -o name) -n consul -c ingress-gateway -- wget -qO- 127.0.0.1:19000/config_dump | jq '[.. |."dynamic_route_configs"? | select(. != null)[0]]'


