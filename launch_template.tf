# ## Fetch the appropriate Amazon Machine Image (AMI)
# data "aws_ami" "eks_worker_ami" {
#   most_recent = true
#   owners      = ["602401143452"]  # Amazon EKS AMI owner ID

#   filter {
#     name   = "name"
#     values = ["amazon-eks-node-1.30-v*"]  # Specify your desired Kubernetes version
#   }

#   filter {
#     name   = "architecture"
#     values = ["x86_64"]
#   }
# }

# ## 
# resource "aws_launch_template" "node_group_template" {
#   name          = "${var.project}-${var.env}-launch-template"
#   image_id      = data.aws_ami.eks_worker_ami.id

#   network_interfaces {
#     security_groups = [aws_security_group.eks_node_group_sg.id]
#   }

# # Root volume configuration (set to gp3)
#   block_device_mappings {
#     device_name = "/dev/xvda"  # Default root volume
#     ebs {
#       volume_size = 30      # Specify the size (GB)
#       volume_type = "gp3"   # Set to gp3 volume type
#       delete_on_termination = true
#     }
#   }

# # Add any additional tags here
#   tag_specifications {
#     resource_type = "instance"  # Tag the EC2 instances
#     tags = merge(
#       local.default_tags,
#       {
#         Name                     = "${var.project}-${var.env}-eks-node"
#         "karpenter.sh/discovery" = local.cluster_name
#       }
#     )
#   }

#   tag_specifications {
#     resource_type = "volume"  # Tag the EBS volumes
#     tags = merge(
#       local.default_tags,
#       {
#         Name                     = "${var.project}-${var.env}-eks-node-volume"
#         "karpenter.sh/discovery" = local.cluster_name
#       }
#     )
#   }

#   tags = merge(
#     local.default_tags,
#     {
#       Name                     = "${var.project}-${var.env}-eks-nodegroup-template"
#       "karpenter.sh/discovery" = local.cluster_name
#     }
#   )
# }
