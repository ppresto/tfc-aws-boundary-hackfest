/*
Set the following Env variables to connect to HCP
  variable "HCP_CLIENT_SECRET"
  variable "HCP_CLIENT_ID"
*/

variable "prefix" {
  description = "unique prefix for resources"
  type        = string
  default     = "presto"
}
variable "organization" { default = "my_org_name" }
variable "env" { default = "dev" }

variable "hvn_id" {
  description = "The ID of the HCP HVN."
  type        = string
  default     = "learn-hvn"
}
# HCP Consul Virtual Network CIDR
variable "hvn_cidr_block" {
  description = "VPC CIDR Block Range"
  type        = string
  default     = "172.25.16.0/20"
}
# AWS Shared VPC CIDR
variable "vpc_cidr_block" {
  description = "VPC CIDR Block Range"
  type        = string
  default     = "10.21.0.0/16"
}
# Shared bastion host allowed ingress CIDR
variable "allowed_bastion_cidr_blocks" {
  description = "List of CIDR blocks allowed to access your Bastion.  Defaults to Everywhere."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
# Private Network Trusted CIDR blocks
variable "private_cidr_blocks" {
  description = "List of CIDR blocks participating in HCP Consul Shared service"
  type        = list(string)
  default     = ["10.0.0.0/10"]
}
variable "cluster_id" {
  description = "The ID of the HCP Consul cluster."
  type        = string
  default     = "learn-hcp-consul"
}
variable "min_consul_version" {
  description = "Minimum version of HCP Consul"
  type        = string
  default     = "1.12.4"
}
variable "region" {
  description = "The region of the HCP HVN and Consul cluster."
  type        = string
  default     = "us-west-2"
}
variable "cloud_provider" {
  description = "The cloud provider of the HCP HVN and Consul cluster."
  type        = string
  default     = "aws"
}
# EC2 Variables
variable "ami_id" {
  description = "AMI ID to be used on all AWS EC2 Instances."
  type        = string
  default     = "ami-0747bdcabd34c712a" # Latest Ubuntu 18.04 LTS (HVM), SSD Volume Type
}

variable "use_latest_ami" {
  description = "Whether or not to use the hardcoded ami_id value or to grab the latest value from SSM parameter store."
  type        = bool
  default     = true
}

variable "ec2_key_pair_name" {
  description = "An existing EC2 key pair used to access the bastion server."
  type        = string
  default     = "ppresto-ptfe-dev-key"
}
variable "allowed_bastion_cidr_blocks_ipv6" {
  description = "List of CIDR blocks allowed to access your Bastion.  Defaults to none."
  type        = list(string)
  default     = []
}

locals {
  region_shortname = join("", regex("([a-z]{2}).*-([a-z]).*-(\\d+)", var.region))
}