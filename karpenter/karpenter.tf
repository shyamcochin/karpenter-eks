# ## Create Karpenter Namespace:
# resource "kubernetes_namespace" "karpenter" {
#   metadata {
#     name = var.karpenter_namespace
#   }
# #   depends_on = [aws_eks_cluster.main]  # Ensures that EKS is created first
# }


# ## Create a Kubernetes service account for Karpenter and annotate it with the IAM role ARN:
# resource "kubernetes_service_account" "karpenter" {
#   metadata {
#     name      = "karpenter-sa"
#     namespace = kubernetes_namespace.karpenter.metadata[0].name
#     annotations = {
#       "eks.amazonaws.com/role-arn" = data.terraform_remote_state.root.outputs.karpenter_controller_role_arn
#     }
#   }
#   depends_on = [kubernetes_namespace.karpenter]
# }


# ## Helm release resource to install Karpenter:
# resource "helm_release" "karpenter" {
#   name             = "karpenter"
#   namespace        = kubernetes_namespace.karpenter.metadata[0].name
#   create_namespace = true
#   repository       = "oci://public.ecr.aws/karpenter"
#   chart            = "karpenter"
#   version          = var.karpenter_version

#   set {
#     name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
#     value = data.terraform_remote_state.root.outputs.karpenter_controller_role_arn
#   }

#   set {
#     name  = "settings.clusterName"
#     value = data.terraform_remote_state.root.outputs.cluster_name
#   }

#   set {
#     name  = "settings.clusterEndpoint"
#     value = data.terraform_remote_state.root.outputs.cluster_endpoint
#   }

#   set {
#     name  = "settings.interruptionQueue"
#     value = data.terraform_remote_state.root.outputs.karpenter_interruption_queue_arn
#   }

#   set {
#     name  = "serviceAccount.create"
#     value = "false"
#   }

#   set {
#     name  = "serviceAccount.name"
#     value = "karpenter"
#   }

#   set {
#     name  = "settings.featureGates.drift"
#     value = "true"
#   }
#   timeout = 900  # Increase timeout to 15 minutes
#   wait = true

#   depends_on = [kubernetes_namespace.karpenter, kubernetes_service_account.karpenter]
# }


# Create Karpenter Namespace
resource "kubernetes_namespace" "karpenter" {
  metadata {
    name = var.karpenter_namespace
  }
}

# Create a Kubernetes service account for Karpenter
resource "kubernetes_service_account" "karpenter" {
  metadata {
    name      = "karpenter"
    namespace = kubernetes_namespace.karpenter.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = data.terraform_remote_state.root.outputs.karpenter_controller_role_arn
    }
  }
  depends_on = [kubernetes_namespace.karpenter]
}

# Helm release resource to install Karpenter
resource "helm_release" "karpenter" {
  name             = "karpenter"
  namespace        = kubernetes_namespace.karpenter.metadata[0].name
  create_namespace = false
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = var.karpenter_version

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.karpenter.metadata[0].name
  }

  set {
    name  = "settings.clusterName"
    value = data.terraform_remote_state.root.outputs.cluster_name
  }

  set {
    name  = "settings.clusterEndpoint"
    value = data.terraform_remote_state.root.outputs.cluster_endpoint
  }

  set {
    name  = "settings.interruptionQueue"
    value = data.terraform_remote_state.root.outputs.karpenter_interruption_queue_name
  }

  set {
    name  = "controller.resources.requests.cpu"
    value = "1"
  }

  set {
    name  = "controller.resources.requests.memory"
    value = "1Gi"
  }

  set {
    name  = "controller.resources.limits.cpu"
    value = "1"
  }

  set {
    name  = "controller.resources.limits.memory"
    value = "1Gi"
  }

  timeout = 300 # Increase timeout to 20 minutes

  depends_on = [kubernetes_namespace.karpenter, kubernetes_service_account.karpenter]
}