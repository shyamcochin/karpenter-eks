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

# resource "helm_release" "karpenter" {
#   name       = "karpenter"
#   repository = "https://charts.karpenter.sh"
#   chart      = "karpenter"
#   namespace  = "karpenter"
#   version    = "v0.27.3"

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

#   depends_on = [aws_eks_node_group.main]
# }