#!/bin/bash

# Check for auto-approve argument
AUTO_APPROVE=""
if [[ "$1" == "--auto-approve" ]]; then
  AUTO_APPROVE="-auto-approve"
fi

# Step 1: Apply Karpenter Helm Chart
# terraform apply -target=kubernetes_config_map_v1_data.aws_auth -target=kubernetes_namespace.karpenter -target=kubernetes_service_account.karpenter -target=helm_release.karpenter -auto-approve
terraform apply -target=kubernetes_config_map_v1_data.aws_auth -target=kubernetes_namespace.karpenter -target=kubernetes_service_account.karpenter -target=helm_release.karpenter $AUTO_APPROVE


# Step 2: Wait for CRDs to be available
until kubectl get crd ec2nodeclasses.karpenter.k8s.aws &>/dev/null; do
  echo "Waiting for EC2NodeClass CRD to be available..."
  sleep 5
done

until kubectl get crd nodepools.karpenter.sh &>/dev/null; do
  echo "Waiting for NodePool CRD to be available..."
  sleep 5
done

# Step 3: Apply EC2NodeClass and NodePool
# terraform apply -target=kubernetes_manifest.karpenter_ec2nodeclass -target=kubernetes_manifest.karpenter_nodepool -auto-approve
terraform apply -target=kubernetes_manifest.karpenter_ec2nodeclass -target=kubernetes_manifest.karpenter_nodepool $AUTO_APPROVE
