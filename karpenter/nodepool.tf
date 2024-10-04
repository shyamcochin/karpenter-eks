resource "kubernetes_manifest" "karpenter_nodepool" {
  manifest = {
    apiVersion = "karpenter.sh/v1beta1"
    kind       = "NodePool"
    metadata = {
      name = "default"
    }
    spec = {
      disruption = {
        consolidateAfter = "30s"
        consolidationPolicy = "WhenEmpty"
        expireAfter = "Never"
      }
      limits = {
        cpu = "10"
      }
      template = {
        metadata = {
          labels = {
            eks-immersion-team = "my-team"
          }
        }
        spec = {
          nodeClassRef = {
            name = "default"
          }
          requirements = [
            {
              key = "karpenter.k8s.aws/instance-category"
              operator = "In"
              values = ["t", "c", "m"]
            },
            {
              key = "kubernetes.io/arch"
              operator = "In"
              values = ["amd64"]
            },
            {
              key = "karpenter.sh/capacity-type"
              operator = "In"
              values = ["on-demand"]
            },
            {
              key = "kubernetes.io/os"
              operator = "In"
              values = ["linux"]
            }
          ]
        }
      }
    }
  }
  # depends_on = [null_resource.wait_for_karpenter_crds_1, null_resource.wait_for_karpenter_crds_2] # Wait for Karpenter CRDs
}
