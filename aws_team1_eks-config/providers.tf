terraform {
  required_version = ">= 1.1.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.74.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.7.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.4.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.13.1"
    }
    consul = {
      source = "hashicorp/consul"
      version = "~> 2.15.1"
    }
  }
}

provider "consul" {
  address    = local.consul_public_url
  datacenter = local.consul_datacenter
  token      = local.consul_root_token
  #ca_file    = base64decode(local.consul_client_ca)
}
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    token                  = data.aws_eks_cluster_auth.cluster.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  }
}
provider "kubectl" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}