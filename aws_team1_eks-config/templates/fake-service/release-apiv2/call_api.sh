#!/bin/bash

HOST=$(kubectl -n consul get svc -o json | jq -r '.items[].status.loadBalancer.ingress | select( . != null) | .[].hostname')

while true
do
  echo "$(date):$(curl -s \
    --request GET \
   http://${HOST}:8080 \
   | jq -r '.upstream_calls' | grep name)"

  sleep 1
done
