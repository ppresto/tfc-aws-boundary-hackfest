#!/bin/bash
export CONSUL_HTTP_TOKEN="${SERVICE_ACL_TOKEN}"


# Start API Service
export MESSAGE="API RESPONSE"
export NAME="api-v1"
export SERVER_TYPE="http"
export LISTEN_ADDR="127.0.0.1:9091"
nohup ./bin/fake-service > logs/fake-service.out 2>&1 &

# Register Service to Consul [ -config-dir=/etc/consul.d/ ]
consul services register ./api-service.hcl

# Start Envoy with Consul
consul connect envoy -sidecar-for api -namespace=api -admin-bind localhost:19000 > logs/envoy.log 2>&1 &