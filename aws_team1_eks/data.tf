# data source for current (working) aws region
data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "terraform_remote_state" "hcp_consul" {
  backend = "remote"
  config = {
    organization = var.organization
    workspaces = {
      name = "aws_${local.region_shortname}_shared_hcp-consul"
    }
  }
}