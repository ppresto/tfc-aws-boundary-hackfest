variable "name" {
  description = "Name to be used on all the resources as identifier."
  type        = string
  default     = "presto"
}
variable "env" { default = "dev" }
variable "consul_template" { default = "fake-service"}
variable "region" {
  description = "AWS region."
  type        = string
  default     = "us-west-2"
}
variable "organization" { default = "my_org_name" }
variable "namespace" {
  description = "K8s Namespace"
  type        = string
  default     = "default"
}
variable "consul_dns_cluster_ip" {
  description = "Preset Consul DNS ClusterIP to configure CoreDNS"
  type        = string
  default     = "172.20.128.87"
}
variable "helm_release_name" { default = "consul" }
locals {
  region_shortname    = join("", regex("([a-z]{2}).*-([a-z]).*-(\\d+)", var.region))
  transit_gateway_id  = data.terraform_remote_state.hcp_consul.outputs.ec2_transit_gateway_id
  hvn_cidr_block      = data.terraform_remote_state.hcp_consul.outputs.hvn_cidr_block
  private_cidr_blocks = ["10.0.0.0/10"]

  # EKS
  eks_cluster_endpoint = data.terraform_remote_state.aws-eks.outputs.cluster_endpoint
  # HCP Consul client data sources
  consul_public_url       = data.terraform_remote_state.hcp_consul.outputs.consul_public_endpoint_url
  consul_config_file      = data.terraform_remote_state.hcp_consul.outputs.consul_config_file
  consul_server_priv_addr = data.terraform_remote_state.hcp_consul.outputs.consul_private_endpoint_url
  consul_datacenter       = data.terraform_remote_state.hcp_consul.outputs.datacenter
  consul_root_token       = data.terraform_remote_state.hcp_consul.outputs.consul_root_token_secret_id
  consul_svcapi_token     = data.terraform_remote_state.hcp_consul.outputs.consul_service_api_token
  consul_client_ca        = data.terraform_remote_state.hcp_consul.outputs.consul_ca_file
  consul_config_file_json = jsondecode(base64decode(data.terraform_remote_state.hcp_consul.outputs.consul_config_file))
  consul_gossip_key       = local.consul_config_file_json.encrypt
  consul_retry_join       = local.consul_config_file_json.retry_join
}