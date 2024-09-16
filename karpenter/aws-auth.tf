data "aws_caller_identity" "current" {}


data "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  # depends_on = [ aws_eks_cluster.main ]
}

resource "kubernetes_config_map_v1_data" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode(
      distinct(concat(
        try(yamldecode(lookup(data.kubernetes_config_map.aws_auth.data, "mapRoles", "[]")), []),
        [
          {
            rolearn  = data.terraform_remote_state.root.outputs.clusternode_iam_role_arn
            username = "system:node:{{EC2PrivateDNSName}}"
            groups   = ["system:bootstrappers", "system:nodes"]
          },
          {
            rolearn  = data.terraform_remote_state.root.outputs.karpenter_node_role_arn
            username = "system:node:{{EC2PrivateDNSName}}"
            groups   = ["system:bootstrappers", "system:nodes"]
          }
        ]
      ))
    )

    mapUsers = yamlencode(
      distinct(concat(
        try(yamldecode(lookup(data.kubernetes_config_map.aws_auth.data, "mapUsers", "[]")), []),
        [
          {
            userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.iam_user}"
            username = "${var.iam_user}"
            groups   = ["system:masters"]
          },
          {
            userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.k8s_user}"
            username = var.k8s_user
            groups   = ["system:masters"]
          }
        ]
      ))
    )
  }

  force = true
  depends_on = [data.kubernetes_config_map.aws_auth]
}


## Existing aws-auth ConfigMap after Deletion
# When you delete and recreate the EKS cluster via Terraform, unless you manually delete the old aws-auth ConfigMap from Kubernetes before recreating the cluster, Kubernetes might still store the ConfigMap information and reuse it.
# kubectl delete configmap aws-auth -n kube-system
# kubectl get all -n kube-system
