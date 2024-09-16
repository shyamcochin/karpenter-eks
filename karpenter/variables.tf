variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region"
}
## Tag Configuration:
#--------------------
variable "project" {
  type        = string
  description = "Project name"
}

variable "env" {
  type        = string
  description = "Environment name"
}

variable "app" {
  type        = string
  description = "Application name"
}

## Karpenter Config
variable "karpenter_version" {
  type = string
  default = "0.37.0"
  description = "Karpenter Version"
}

variable "karpenter_namespace" {
  type = string
  default = "karpenter"
  description = "Karpenter Namespace"
}


## IAM Configuration:
#--------------------
variable "k8s_user" {
  type        = string
  description = "IAM user to be given access to the EKS cluster"
}

variable "iam_user" {
  type        = string
  description = "IAM user to be given access to the EKS cluster"
}