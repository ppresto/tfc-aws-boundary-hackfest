#!/bin/bash
export CONSUL_HTTP_TOKEN="${SERVICE_ACL_TOKEN}"

# Deregister Service to Consul [ -config-dir=/etc/consul.d/ ]
consul services deregister -namespace=api ./api-service.hcl

# Stop Envoy proxy and fake-service processes
pkill envoy
pkill fake-service