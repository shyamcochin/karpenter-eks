# karpenter-eks
Deploying Karpenter in EKS cluster using terraform.

Terraform Commands:
-------------------
terraform init
terraform refresh
terraform plan
terraform apply
terraform apply --auto-approve
terraform output
terraform state list
terraform state rm <resource_name>


Check the Versions:
-------------------
aws --version
kubectl version --client
terraform --version
eksctl version


Configure the AWS CLI:
----------------------
aws configure
aws sts get-caller-identity


Connect to EKS cluster: (Demo-dev-app-eks)
-----------------------
aws eks describe-cluster --name <cluster-name>
aws eks update-kubeconfig --name <cluster-name> --region <region> --alias mydemo
aws eks update-kubeconfig --name Demo-dev-app-eks --region us-east-1 --alias mydemo
kubectl get nodes
kubectl get pod -A



Karpenter Deployment:
----------------------
cd karpenter
terraform init
terraform output -state=../terraform.tfstate
terraform refresh
terraform plan
terraform apply

kubectl get pod -A
kubectl get configmap aws-auth -n kube-system -oyaml

kubectl get crds
kubectl get crds | grep karpenter
kubectl get crds | grep -E 'ec2nodeclass|nodepool'
This should show CRDs like ec2nodeclasses.karpenter.k8s.aws and nodepools.karpenter.sh.


kubectl get deploy -n karpenter
kubectl describe deployment karpenter -n karpenter
kubectl get pods -n karpenter
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
kubectl get all -n karpenter

kubectl get nodepool 
kubectl get nodepool  default -oyaml
kubectl get EC2NodeClass 
kubectl get EC2NodeClass  default -oyaml


Check the AWS-Auth file:
------------------------
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


Testing the Apps:
-----------------
cd ../manifest/
kubectl create namespace workshop
kubectl apply -f inflate.yaml
kubectl get all -n workshop
kubectl get deploy -n workshop
kubectl get node

kubectl scale deployment -n workshop inflate --replicas 5
kubectl scale deployment -n workshop inflate --replicas 0
kubectl delete -f inflate.yaml

kubectl -n karpenter logs -f -l app.kubernetes.io/name=karpenter
kubectl get pod -n workshop
kubectl get node
kubectl get all -n workshop


kubectl delete ec2nodeclass default
terraform apply


helm list -n karpenter
helm uninstall karpenter -n karpenter
helm status karpenter -n karpenter

kubectl delete deployment karpenter -n karpenter
kubectl delete pods -n karpenter --all



aws eks describe-cluster --name Demo-dev-app-eks --region us-east-1 --query "cluster.identity.oidc.issuer" --output text
aws sqs get-queue-url --region us-east-1 --queue-name Demo-dev-app-eks-interruption-queue
aws sqs list-queues
aws sqs get-queue-url --queue-name <QUEUE_NAME>
aws sqs get-queue-attributes --queue-url <QUEUE_URL> --attribute-name All
aws iam get-role-policy --role-name KarpenterControllerRole-Demo-dev-app-eks --policy-name <PolicyName>


terraform console
> data.aws_eks_cluster.example



Notes:
------
Immutable Field Error: The role field in spec for EC2NodeClass is immutable, meaning once it’s set, you cannot change it. If you need to change the role, you’ll have to delete and recreate the EC2NodeClass resource.
kubectl delete ec2nodeclass default


Tagging Subnets for Karpenter: Tagged the subnets with karpenter.sh/discovery, which Karpenter uses to identify the subnets. However, make sure both public and private subnets are tagged properly. 

Tagging Security Groups for Karpenter: Tagged the security group for the EKS control plane. However, Karpenter requires tagging of specific security groups associated with the nodegroups. You'll need to tag these groups explicitly.


terraform console
> data.aws_eks_cluster.example
