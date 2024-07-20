# resource "aws_iam_instance_profile" "karpenter" {
#   name = "KarpenterNodeInstanceProfile-${local.cluster_name}"
#   role = module.eks.eks_managed_node_groups["initial"].iam_role_name
# }

# resource "aws_iam_role" "karpenter_controller" {
#   name = "${var.project}-${var.env}-${var.app}-karpenter-controller"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRoleWithWebIdentity"
#         Effect = "Allow"
#         Principal = {
#           Federated = aws_iam_openid_connect_provider.eks.arn
#         }
#         Condition = {
#           StringEquals = {
#             "${aws_iam_openid_connect_provider.eks.url}:sub" = "system:serviceaccount:karpenter:karpenter"
#           }
#         }
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "karpenter_controller_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
#   role       = aws_iam_role.karpenter_controller.name
# }

# resource "kubernetes_namespace" "karpenter" {
#   metadata {
#     name = "karpenter"
#   }
# }

# resource "helm_release" "karpenter" {
#   name       = "karpenter"
#   #create_namespace = true

#   repository = "https://charts.karpenter.sh"
#   chart      = "karpenter"
#   namespace  = "karpenter"
#   version    = "0.16.3"  # Updated to the latest available version

#   set {
#     name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
#     value = aws_iam_role.karpenter_controller.arn
#   }

#   set {
#     name  = "clusterName"
#     value = aws_eks_cluster.main.name
#   }

#   set {
#     name  = "clusterEndpoint"
#     value = aws_eks_cluster.main.endpoint
#   }
#   set {
#     name  = "aws.defaultInstanceProfile"
#     value = aws_iam_instance_profile.karpenter.name
#   }

#   depends_on = [aws_eks_node_group.main, kubernetes_namespace.karpenter]
# }


# # # Define the EC2NodeClass manifest
# # resource "kubernetes_manifest" "ec2nodeclass" {
# #   manifest = yamlencode({
# #     apiVersion = "karpenter.k8s.aws/v1alpha1"
# #     kind       = "EC2NodeClass"
# #     metadata = {
# #       name = "example-ec2nodeclass"
# #     }
# #     spec = {
# #       subnetSelector = {
# #         "karpenter.sh/discovery" = "${local.cluster_name}"
# #       }
# #       securityGroupSelector = {
# #         "karpenter.sh/discovery" = "${local.cluster_name}"
# #       }
# #       instanceProfile = "KarpenterNodeInstanceProfile"
# #       instanceTypes = [
# #         "m5.large",
# #         "m5.xlarge"
# #       ]
# #     }
# #   })
# #   depends_on = [ helm_release.karpenter, aws_eks_cluster.main ]
# # }

# # # Define the NodePool manifest
# # resource "kubernetes_manifest" "nodepool" {
# #   manifest = jsonencode({
# #     apiVersion = "karpenter.sh/v1alpha5"
# #     kind       = "NodePool"
# #     metadata = {
# #       name = "example-nodepool"
# #     }
# #     spec = {
# #       template = {
# #         spec = {
# #           nodeClass = {
# #             kind = "EC2NodeClass"
# #             name = "example-ec2nodeclass"
# #           }
# #           capacityType = "spot"
# #           taints = [
# #             {
# #               key    = "example-taint"
# #               value  = "example-value"
# #               effect = "NoSchedule"
# #             }
# #           ]
# #           labels = {
# #             example-label = "example-value"
# #           }
# #           requirements = [
# #             {
# #               key      = "kubernetes.io/arch"
# #               operator = "In"
# #               values   = ["amd64"]
# #             },
# #             {
# #               key      = "karpenter.sh/capacity-type"
# #               operator = "In"
# #               values   = ["spot", "on-demand"]
# #             }
# #           ]
# #           limits = {
# #             resources = {
# #               cpu    = "1000"
# #               memory = "1000Gi"
# #             }
# #           }
# #         }
# #       }
# #     }
# #   })

# #   depends_on = [
# #     kubernetes_manifest.ec2nodeclass
# #   ]
# # }
