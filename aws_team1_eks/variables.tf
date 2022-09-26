
# This prefix will be used in your EKS cluster name.
# Update the ./aws_eks/awscli_eks_connect.sh with your EKS cluster name to connect.
variable "prefix" {
  description = "Unique name to identify all resources. Try using your name."
  type        = string
  default     = "presto"
}

variable "env" { default = "dev" }
# The EKS cluster will be created in this region.
# Update ./aws_eks/awscli_eks_connect.sh with your region value to connect.
variable "region" {
  description = "AWS region."
  type        = string
  default     = "us-west-2"
}
variable "organization" { default = "my_org_name" }

variable "ec2_key_pair_name" {
  description = "An existing EC2 key pair used to access the bastion server."
  type        = string
  default     = "my-aws-ssh-key-pair"
}
variable "vpc_cidr_block" {
  description = "VPC CIDR Block Range"
  type        = string
  default     = "10.15.0.0/16"
}
locals {
  region_shortname    = join("", regex("([a-z]{2}).*-([a-z]).*-(\\d+)", var.region))
  transit_gateway_id  = data.terraform_remote_state.hcp_consul.outputs.ec2_transit_gateway_id
  hvn_cidr_block      = data.terraform_remote_state.hcp_consul.outputs.hvn_cidr_block
  private_cidr_blocks = ["10.0.0.0/10"]

  # HCP Consul client data sources
  consul_config_file      = data.terraform_remote_state.hcp_consul.outputs.consul_config_file
  consul_server_priv_addr = data.terraform_remote_state.hcp_consul.outputs.consul_private_endpoint_url
  consul_datacenter       = data.terraform_remote_state.hcp_consul.outputs.datacenter
  consul_root_token       = data.terraform_remote_state.hcp_consul.outputs.consul_root_token_secret_id
  consul_svcapi_token     = data.terraform_remote_state.hcp_consul.outputs.consul_service_api_token
  consul_client_ca        = data.terraform_remote_state.hcp_consul.outputs.consul_ca_file
  #consul_config_file_json = jsondecode(base64decode(data.terraform_remote_state.hcp_consul.outputs.consul_config_file))
  #consul_gossip_key       = local.consul_config_file_json.encrypt
  #consul_retry_join       = local.consul_config_file_json.retry_join
}