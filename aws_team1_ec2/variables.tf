variable "prefix" {
  description = "Name to be used on all the resources as identifier."
  type        = string
  default     = "presto"
}
variable "env" { default = "dev" }
variable "region" {
  description = "AWS region."
  type        = string
  default     = "us-west-2"
}
variable "organization" { default = "my_org_name" }

variable "ec2_key_pair_name" {
  description = "An existing EC2 key pair used to access the bastion server."
  type        = string
  default     = "ppresto-ptfe-dev-key"
}
variable "vpc_cidr_block" {
  description = "VPC CIDR Block Range"
  type        = string
  default     = "10.20.0.0/16"
  #default     = "0.0.0.0/0"
}
variable "private_subnets" {
  description = "VPC subnets"
  type        = list(any)
  default     = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]
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
