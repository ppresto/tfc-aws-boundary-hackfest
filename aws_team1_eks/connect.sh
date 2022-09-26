#!/bin/bash

# Setup local AWS Env variables

# AWS Target Region needed by CLI.
if [[ ! -z $AWS_REGION ]]; then
    AWS_DEFAULT_REGION="${AWS_REGION}"
fi
if [[ -z $AWS_DEFAULT_REGION ]]; then
    echo "Input AWS Target Region (ex: us-west-2):"
    read AWS_DEFAULT_REGION
    echo "Connecting to region $AWS_DEFAULT_REGION"
fi

# get identity
aws sts get-caller-identity

# add EKS cluster to $HOME/.kube/config
aws eks --region $AWS_DEFAULT_REGION update-kubeconfig --name presto-aws-team1-eks
