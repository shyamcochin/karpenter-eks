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
  wait = true # Ensure Helm waits for all resources to be ready, including CRDs

  depends_on = [kubernetes_namespace.karpenter, kubernetes_service_account.karpenter]
}


# resource "null_resource" "wait_for_karpenter_crds_1" {
#   provisioner "local-exec" {
#     command = "sleep 30"  # Add a delay of 30 seconds
#   }
#   depends_on = [helm_release.karpenter]
# }


# ## Add a null_resource to Wait for the CRDs
# resource "null_resource" "wait_for_karpenter_crds_2" {
#   provisioner "local-exec" {
#     command = <<EOT
#       for i in {1..30}; do
#         kubectl get crd ec2nodeclasses.karpenter.k8s.aws && kubectl get crd nodepools.karpenter.sh && exit 0
#         echo "Waiting for Karpenter CRDs..."
#         sleep 5
#       done
#       echo "Timed out waiting for Karpenter CRDs"
#       exit 1
#     EOT
#   }
#   depends_on = [helm_release.karpenter]
# }

