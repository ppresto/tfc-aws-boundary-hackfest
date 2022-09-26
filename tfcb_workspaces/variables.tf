# TFC variables
variable "tfe_token" {}
variable "tfe_hostname" { default = "app.terraform.io" }
variable "oauth_token_id" {}
variable "organization" { default = "" }
variable "repo_org" {}
variable "tag_names" {
  type    = list(any)
  default = ["auto"]
}
variable "variable_set" { default = null }

# HCP variables
variable "HCP_CLIENT_ID" { default = "" }
variable "HCP_CLIENT_SECRET" { default = "" }

# Env variables
variable "ssh_key_name" { default = "" }
variable "env" { default = "dev" }

# Cloud Provider variables
variable "aws_default_region" { default = "us-west-2" }
variable "aws_secret_access_key" { default = "" }
variable "aws_access_key_id" { default = "" }
variable "gcp_region" { default = "" }
variable "gcp_zone" { default = "" }
variable "gcp_project" { default = "" }
variable "gcp_credentials" { default = "" }
variable "arm_subscription_id" { default = "" }
variable "arm_client_secret" { default = "" }
variable "arm_tenant_id" { default = "" }
variable "arm_client_id" { default = "" }

locals {
  region_shortname = join("", regex("([a-z]{2}).*-([a-z]).*-(\\d+)", var.aws_default_region))
}