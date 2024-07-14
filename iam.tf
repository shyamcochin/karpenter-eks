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

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

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


# ## EKS Cluster with Add-On VPC CNI
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





## SPOT Server: use a data source to check for the role, and then create it if the data source returns an error.
# # Check if the spot instance role exists
# data "aws_iam_role" "spot_role" {
#   name = "AmazonEC2SpotFleetTaggingRole"
#   count = 0 # Set to 0 to avoid errors if the role doesn't exist
# }

# # Create the spot instance role if it doesn't exist
# resource "aws_iam_role" "spot_role" {
#   count = length(data.aws_iam_role.spot_role) > 0 ? 0 : 1
#   name  = "AmazonEC2SpotFleetTaggingRole"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "spotfleet.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

# # Attach the necessary policy to the spot instance role
# resource "aws_iam_role_policy_attachment" "spot_role_policy" {
#   count      = length(data.aws_iam_role.spot_role) > 0 ? 0 : 1
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole"
#   role       = aws_iam_role.spot_role[0].name
# }