#!/bin/bash

retry=3
while [ $retry -gt 0 ]
do
	status_code=$(curl --write-out %{http_code} --silent --output /dev/null http://localhost:8500/v1/status/leader)
  if [[ "${status_code}" != "200" ]]; then
    retry=$(($retry - 1))
    sleep 5
  else
    echo $status_code
    break
  fi
done