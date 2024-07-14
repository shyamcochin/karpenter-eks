# Retrieve AWS account ID
data "aws_caller_identity" "current" {}

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode(
      [{
        rolearn  = aws_iam_role.eks_nodes.arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }]
    )
    mapUsers = yamlencode(
      [{
        userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/syam.kumar"
        username = "syam.kumar"
        groups   = ["system:masters"]
      },
      {
        userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.k8s_user}"
        username = "${var.k8s_user}"
        groups   = ["system:masters"]
      }]
    )
  }

  depends_on = [aws_eks_cluster.main]
}

