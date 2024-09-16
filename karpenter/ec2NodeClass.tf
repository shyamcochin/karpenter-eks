resource "kubernetes_manifest" "karpenter_ec2nodeclass" {
  manifest = {
    apiVersion = "karpenter.k8s.aws/v1beta1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "default"
    }
    spec = {
      amiFamily = "AL2"
      role      = data.terraform_remote_state.root.outputs.karpenter_node_role_name
      securityGroupSelectorTerms = [
        {
          tags = {
            "karpenter.sh/discovery" = local.cluster_name
          }
        }
      ]
      subnetSelectorTerms = [
        {
          tags = {
            "karpenter.sh/discovery" = local.cluster_name
          }
        }
      ]

      tags = merge(
        local.default_tags,
        {
          Name                     = "${var.project}-${var.env}-${var.app}-karpenter-node"
          "karpenter.sh/discovery" = local.cluster_name
        }
      )
    }
  }
}
