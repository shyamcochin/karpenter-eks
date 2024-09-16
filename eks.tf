resource "aws_eks_cluster" "main" {
  name     = local.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.30"

  vpc_config {
    # subnet_ids              = concat(aws_subnet.private[*].id)
    subnet_ids              = concat(aws_subnet.private[*].id, aws_subnet.public[*].id)
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.eks_control_plane_sg.id]
  }

  # Enable Control Plane Logging
  enabled_cluster_log_types = var.enable_ekscluster_logs ? ["api", "audit", "authenticator", "controllerManager", "scheduler"] : []

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSServicePolicy,
  ]

  tags = merge(
    local.default_tags,
    {
      Name                     = "${var.project}-${var.env}-${var.app}-eks"
      "karpenter.sh/discovery" = local.cluster_name
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

  # Associate the security group with the node group
  # launch_template {
  #   id      = aws_launch_template.node_group_template.id
  #   version = aws_launch_template.node_group_template.latest_version
  # }

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 2
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
    aws_iam_role_policy_attachment.eks_nodes_AmazonSSMManagedInstanceCore,
    # aws_launch_template.node_group_template
  ]

  tags = merge(
    local.default_tags,
    {
      Name                     = "${var.project}-${var.env}-${var.app}-nodegroup"
      "karpenter.sh/discovery" = local.cluster_name
    }
  )
}

## Create an IAM OIDC provider for your EKS cluster 
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}


## EKS-Managed add-ons
# AWS strongly recommends using EKS-managed add-ons for components like vpc-cni, CoreDNS, and kube-proxy. 
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"
  # service_account_role_arn = aws_iam_role.eks_cni_role.arn

  depends_on = [
    aws_eks_cluster.main,
    aws_eks_node_group.main,
  ]
}
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"
  # service_account_role_arn = aws_iam_role.eks_coredns_role.arn

  depends_on = [
    aws_eks_cluster.main,
    aws_eks_node_group.main,
  ]
}
resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"
  # service_account_role_arn = aws_iam_role.eks_kubeproxy_role.arn

  depends_on = [
    aws_eks_cluster.main,
    aws_eks_node_group.main
  ]
}
