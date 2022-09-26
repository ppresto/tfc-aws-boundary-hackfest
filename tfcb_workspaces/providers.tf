provider "tfe" {
  hostname = var.tfe_hostname
  token    = var.tfe_token
}

terraform {
  required_version = ">= 1.0.5"
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~>0.36.0"
    }
  }
}

