# Launch Template for Node Group (optional but recommended for customization)
resource "aws_launch_template" "node_group" {
  name_prefix            = "${var.project_name}-node-"
  description            = "Launch template for EKS nodes"
  update_default_version = true

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.node_disk_size
      volume_type           = var.node_disk_type
      delete_on_termination = true
      encrypted             = true
      iops                  = var.node_disk_iops
      throughput            = var.node_disk_throughput
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # IMDSv2 only (security best practice)
    http_put_response_hop_limit = 2
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-node"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "${var.project_name}-node-volume"
    }
  }

  tags = {
    Name = "${var.project_name}-launch-template"
  }
}

# Primary Node Group
resource "aws_eks_node_group" "main" {
  cluster_name           = aws_eks_cluster.main.name
  node_group_name_prefix = "${var.cluster_name}-primary-"
  node_role_arn          = aws_iam_role.node_group.arn
  subnet_ids             = aws_subnet.private[*].id
  version                = var.kubernetes_version

  scaling_config {
    desired_size = var.desired_node_count
    max_size     = var.max_node_count
    min_size     = var.min_node_count
  }

  launch_template {
    id      = aws_launch_template.node_group.id
    version = aws_launch_template.node_group.latest_version_number
  }

  instance_types = var.node_instance_types

  disk_size = var.node_disk_size

  # Enable IMDSv2
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tags = {
    Name = "${var.cluster_name}-primary-nodes"
  }

  # Ensure proper ordering of resource creation/destruction
  depends_on = [
    aws_iam_role_policy_attachment.node_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
    aws_iam_role_policy_attachment.node_ecr_policy,
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# Optional: Additional Spot Node Group for cost optimization
resource "aws_eks_node_group" "spot" {
  count                  = var.create_spot_node_group ? 1 : 0
  cluster_name           = aws_eks_cluster.main.name
  node_group_name_prefix = "${var.cluster_name}-spot-"
  node_role_arn          = aws_iam_role.node_group.arn
  subnet_ids             = aws_subnet.private[*].id
  version                = var.kubernetes_version

  scaling_config {
    desired_size = var.spot_desired_size
    max_size     = var.spot_max_size
    min_size     = var.spot_min_size
  }

  capacity_type = "SPOT"

  instance_types = var.spot_instance_types

  disk_size = var.node_disk_size

  tags = {
    Name = "${var.cluster_name}-spot-nodes"
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
    aws_iam_role_policy_attachment.node_ecr_policy,
  ]

  lifecycle {
    create_before_destroy = true
  }
}
