variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region"
}

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

variable "create_nat" {
  type        = bool
  default     = false
  description = "Whether to create a NAT Gateway"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block for the VPC"
}

variable "k8s_user" {
  type        = string
  description = "IAM user to be given access to the EKS cluster"
}