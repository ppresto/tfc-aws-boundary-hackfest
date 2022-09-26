#!/bin/bash

HOST=$(kubectl -n consul get svc -o json | jq -r '.items[].status.loadBalancer.ingress | select( . != null) | .[].hostname')

echo "Normal Request with no special header"
curl -s \
 --header "baggage:app=api;trace=data" \
 --request GET \
 http://${HOST}:8080 \
 | jq -r '.upstream_calls' | grep name

echo ""
echo "Special Request with baggage header containing matching regex 'version=2'"
echo " curl -s --header \"baggage:version=2;app=api;trace=data\" http://${HOST}:8080"
while true
do
  curl -s \
    --header "baggage:version=2;app=api;trace=data" \
    --request GET \
   http://${HOST}:8080 \
   | jq -r '.upstream_calls' | grep name | grep api
  sleep 1
done
