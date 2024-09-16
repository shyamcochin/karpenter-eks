terraform {
  required_version = ">= 1.8.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.14"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

data "terraform_remote_state" "root" {
  backend = "s3"
  config = {
    bucket = "mytest-terraform-state-bucket"
    key    = "terraform/state.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.root.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.root.outputs.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.root.outputs.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.root.outputs.cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.root.outputs.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.root.outputs.cluster_name]
    }
  }
}