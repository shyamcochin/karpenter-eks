## Testing Remote State Output
output "eks_cluster_name" {
  value = data.terraform_remote_state.root.outputs.cluster_name
}

output "eks_cluster_endpoint" {
  value = data.terraform_remote_state.root.outputs.cluster_endpoint
}

