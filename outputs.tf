## VPC Outputs 
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "db_subnet_ids" {
  description = "List of IDs of db subnets"
  value       = aws_subnet.db[*].id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway (if created)"
  value       = var.create_nat ? aws_nat_gateway.main[0].id : null
}

## EKS Cluster Outputs
output "cluster_name" {
  description = "Cluster Name"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_iam_role_name" {
  description = "IAM role name of the EKS cluster"
  value       = aws_iam_role.eks_cluster.name
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "clusternode_iam_role_arn" {
  description = "IAM role name of the EKS cluster Node group"
  value       = aws_iam_role.eks_nodes.arn
}

output "cluster_token" {
  value = data.aws_eks_cluster_auth.cluster.token
  sensitive = true
}

output "cluster_oidc_issuer" {
  description = "EKS cluster OIDC ARN"
  value = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# AWS account ID and IAM user details
output "aws_account_id" {
  description = "The AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_user_arn" {
  description = "The ARN of the IAM user"
  value       = data.aws_caller_identity.current.arn
}

output "aws_user_id" {
  description = "The ID of the IAM user"
  value       = data.aws_caller_identity.current.user_id
}

## Karpenter IAM Role:
output "karpenter_controller_role_arn" {
  value       = aws_iam_role.karpenter_controller.arn
  description = "ARN of the Karpenter Controller IAM role"
}

output "karpenter_node_role_arn" {
  value       = aws_iam_role.karpenter_node_role.arn
  description = "ARN of the Karpenter Node IAM role"
}
output "karpenter_node_role_name" {
  value       = aws_iam_role.karpenter_node_role.name
  description = "ARN of the Karpenter Node IAM role"
}


output "karpenter_interruption_queue_name" {
  value = aws_sqs_queue.karpenter_interruption_queue.name
  description = "SQS ARN"
}