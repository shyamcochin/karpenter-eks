resource "aws_eks_cluster" "main" {
  name     = local.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.30"

  vpc_config {
    subnet_ids              = concat(aws_subnet.private[*].id, aws_subnet.public[*].id)
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy,
  ]

  tags = merge(
    local.default_tags,
    {
      Name = "${var.project}-${var.env}-${var.app}-eks"
    }
  )
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project}-${var.env}-${var.app}-nodegroup"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = aws_subnet.private[*].id
  instance_types  = ["t3a.medium"]
  #   capacity_type   = "SPOT"

  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  disk_size = 30 # Set disk size to 30 GB

  depends_on = [
    aws_eks_cluster.main,
    aws_iam_role_policy_attachment.eks_nodes_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_nodes_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_nodes_AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = merge(
    local.default_tags,
    {
      Name = "${var.project}-${var.env}-${var.app}-nodegroup"
    }
  )
}

# OpenID Connect Provider
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# ## EKS-managed add-ons
# resource "aws_eks_addon" "vpc_cni" {
#   cluster_name             = aws_eks_cluster.main.name
#   addon_name               = "vpc-cni"
#   service_account_role_arn = aws_iam_role.eks_cni_role.arn
#   #   addon_version = "v1.12.0-eksbuild.1"  # replace with your desired version
#   depends_on = [
#     aws_eks_cluster.main,
#     aws_eks_node_group.main,
#   ]
# }

# resource "aws_eks_addon" "coredns" {
#   cluster_name             = aws_eks_cluster.main.name
#   addon_name               = "coredns"
#   service_account_role_arn = aws_iam_role.eks_coredns_role.arn
#   depends_on = [
#     aws_eks_cluster.main,
#     aws_eks_node_group.main,
#   ]
# }

# resource "aws_eks_addon" "kube_proxy" {
#   cluster_name             = aws_eks_cluster.main.name
#   addon_name               = "kube-proxy"
#   service_account_role_arn = aws_iam_role.eks_kubeproxy_role.arn
#   depends_on = [
#     aws_eks_cluster.main,
#     aws_eks_node_group.main
#   ]
# }
