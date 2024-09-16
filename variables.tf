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

## VPC Configuration:
#--------------------
variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block for the VPC"
}
variable "create_nat" {
  type        = bool
  default     = false
  description = "Whether to create a NAT Gateway"
}
variable "create_private_subnet" {
  type        = bool
  default     = true
  description = "Whether to create a Private Subnet"
}
variable "create_db_subnet" {
  type        = bool
  default     = true
  description = "Whether to create a DB Subnet"
}


## EKS Configurations:
#---------------------
variable "enable_ekscluster_logs" {
  type        = bool
  default     = false
  description = "Set to True, if you want to enable logging"
}
