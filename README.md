# karpenter-eks
Deploying Karpenter in EKS cluster using terraform.

# Terraform Commands Examples:
------------------------------
terraform init
terraform refresh
terraform plan
terraform apply
terraform apply --auto-approve
terraform output
terraform state list
terraform state rm <resource_name>
terraform console


# Check the Versions:
---------------------
aws --version
kubectl version --client
terraform --version
eksctl version



# Configure the AWS CLI:
------------------------
aws configure
aws sts get-caller-identity


# Create Karpenter Infrastructure:
----------------------------------
terraform init
terraform plan
terraform apply
terraform output -state=../terraform.tfstate


# Connect to EKS cluster: (Demo-dev-app-eks)
--------------------------------------------
aws eks describe-cluster --name <cluster-name>
aws eks update-kubeconfig --name <cluster-name> --region <region> --alias mydemo
aws eks update-kubeconfig --name Demo-dev-app-eks --region us-east-1 --alias mydemo
kubectl get nodes
kubectl get pod -A



# Karpenter Deployment in EKS Cluster:
--------------------------------------
## Note: 1st Comment the ec2NodeClass.tf and nodePool.tf file. If not comment this, you will get CRD error while terrafrom apply time.
## Once completed Kaerpenter deployment via terraform, we can uncomment these file and appy once again.
cd karpenter
terraform init
terraform plan
terraform apply

kubectl get pod -A
kubectl get configmap aws-auth -n kube-system -oyaml

## This should show CRDs like ec2nodeclasses.karpenter.k8s.aws and nodepools.karpenter.sh.
kubectl get crds
kubectl get crds | grep karpenter
kubectl get crds | grep -E 'ec2nodeclass|nodepool'

# Deploy NodePool and EC2NodeClass:
-----------------------------------
## Once completed Kaerpenter deployment via terraform, we can uncomment these file and appy once again.
terraform plan
terraform apply

kubectl get nodepool 
kubectl get nodepool  default -oyaml
kubectl get ec2nodeclass 
kubectl get ec2nodeclass  default -oyaml

## OR ##
---------
## You can simple execute this script.
# Note: The script checks if the first argument ($1) passed to it is --auto-approve.
cd karpenter
bash karpenter_script.sh --auto-approve
kubectl get crds
kubectl get pod -A
kubectl get all -n karpenter



# Verify the Deployments:
-------------------------
kubectl get crds
kubectl get pod -A
kubectl get all -n karpenter
kubectl get deploy -n karpenter
kubectl describe deployment karpenter -n karpenter
kubectl describe pod <pod-name> -n karpenter
kubectl logs <pod-name> -n karpenter
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter
kubectl get deployment -n karpenter karpenter -o jsonpath="{.spec.template.spec.containers[0].image}"
kubectl get events -n karpenter
kubectl get configmap -n karpenter
kubectl describe configmap <CONFIGMAP_NAME> -n karpenter
kubectl get secret -n karpenter
kubectl describe secret <SECRET_NAME> -n karpenter
kubectl get serviceaccount -n karpenter
kubectl rollout restart deployment karpenter -n karpenter


# Testing the Apps and Scale:
-----------------------------
cd ../manifest/
kubectl apply -f inflate.yaml
kubectl get all
kubectl get deploy
kubectl get deploy inflate -oyaml
kubectl get node

kubectl scale deployment inflate --replicas 5
kubectl scale deployment inflate --replicas 0
kubectl delete -f inflate.yaml
kubectl delete deployment karpenter -n karpenter
kubectl delete pods -n karpenter --all


# Monitor the Karpenter Scale:
------------------------------
kubectl -n karpenter logs -f -l app.kubernetes.io/name=karpenter
kubectl get pod -w
kubectl get pod -o wide
kubectl get node -w
kubectl get all
eks-node-viewer


# Check the AWS-Auth file: (Optional)
-------------------------------------
kubectl get configmap aws-auth -n kube-system -oyaml
kubectl edit configmap aws-auth -n kube-system
data:
  mapRoles: |
    - rolearn: arn:aws:iam::123456789012:role/eksctl-my-cluster-nodegroup-NodeInstanceRole-XYZ
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
  mapUsers: |
    - userarn: arn:aws:iam::123456789012:user/terraform-user
      username: terraform-user
      groups:
        - system:masters

Delete existing Auth file (Optional):
-------------------------------------
kubectl delete configmap aws-auth -n kube-system


# Helm Commands:
----------------
helm list -n karpenter
helm uninstall karpenter -n karpenter
helm status karpenter -n karpenter


# AWS CLI Commands:
--------------------
aws eks describe-cluster --name Demo-dev-app-eks --region us-east-1 --query "cluster.identity.oidc.issuer" --output text
aws sqs get-queue-url --region us-east-1 --queue-name Demo-dev-app-eks-interruption-queue
aws sqs list-queues
aws sqs get-queue-url --queue-name <QUEUE_NAME>
aws sqs get-queue-attributes --queue-url <QUEUE_URL> --attribute-name All
aws iam get-role-policy --role-name KarpenterControllerRole-Demo-dev-app-eks --policy-name <PolicyName>



# Notes:
--------
Immutable Field Error: The role field in spec for EC2NodeClass is immutable, meaning once it’s set, you cannot change it. If you need to change the role, you’ll have to delete and recreate the EC2NodeClass resource.
kubectl delete ec2nodeclass default

Tagging Subnets for Karpenter: Tagged the subnets with karpenter.sh/discovery, which Karpenter uses to identify the subnets. However, make sure both public and private subnets are tagged properly. 

Tagging Security Groups for Karpenter: Tagged the security group for the EKS control plane. However, Karpenter requires tagging of specific security groups associated with the nodegroups. You'll need to tag these groups explicitly.