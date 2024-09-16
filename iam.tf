## Create EKS Cluster IAM Role and Attach the Policy
resource "aws_iam_role" "eks_cluster" {
  name = "${var.project}-${var.env}-${var.app}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

# AmazonEKSClusterPolicy: Allows EKS to perform actions necessary for managing the Kubernetes control plane.
resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# AmazonEKSServicePolicy: Enables EKS to manage Elastic Load Balancers, security groups, and other networking components required by the EKS cluster.
resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster.name
}

## Create EKS Cluster WorkerNodeGroup IAM Role and Attach the Policy
resource "aws_iam_role" "eks_nodes" {
  name = "${var.project}-${var.env}-${var.app}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_nodes_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_nodes_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_nodes_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_nodes_AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.eks_nodes.name
}


## Create Karpenter Node Role:
resource "aws_iam_role" "karpenter_node_role" {
  name = "KarpenterNodeRole-${local.cluster_name}"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]
}


## IAM Policy for Karpenter Controller:
resource "aws_iam_policy" "karpenter_controller_policy" {
  name = "KarpenterControllerPolicy-${local.cluster_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "*"
        Resource = "*"
      }
    ]
  })
}

## Create an IAM role for the Karpenter controller with the necessary trust relationship
resource "aws_iam_role" "karpenter_controller" {
  name = "KarpenterControllerRole-${local.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" : "system:serviceaccount:karpenter:karpenter",
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_controller_policy" {
  policy_arn = aws_iam_policy.karpenter_controller_policy.arn
  role       = aws_iam_role.karpenter_controller.name
}




# ## EKS Cluster with Add-On VPC CNI
# # You can create IAM roles for these add-ons as needed, but AWS can manage these roles for you.
# resource "aws_iam_role" "eks_cni_role" {
#   name = "AmazonEKS_CNI_Role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Principal = {
#           Service = "eks.amazonaws.com"
#         },
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "eks_cni_policy_attachment" {
#   role       = aws_iam_role.eks_cni_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
# }


# ## EKS Cluster with Add-On CoreDNS
# resource "aws_iam_role" "eks_coredns_role" {
#   name = "AmazonEKS_CoreDNS_Role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Principal = {
#           Service = "eks.amazonaws.com"
#         },
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "eks_coredns_policy_attachment" {
#   role       = aws_iam_role.eks_coredns_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_Coredns_Policy"
# }

# ## EKS Cluster with Add-On Kube-Proxy
# resource "aws_iam_role" "eks_kubeproxy_role" {
#   name = "AmazonEKS_KubeProxy_Role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Principal = {
#           Service = "eks.amazonaws.com"
#         },
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "eks_kubeproxy_policy_attachment" {
#   role       = aws_iam_role.eks_kubeproxy_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_KubeProxy_Policy"
# }

