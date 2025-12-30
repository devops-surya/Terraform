variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "my-project"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "Must have at least 2 public subnets for high availability."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "Must have at least 2 private subnets for high availability."
  }
}

# EKS Cluster Configuration
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "my-eks-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the cluster"
  type        = string
  default     = "1.29"

  validation {
    condition     = can(regex("^1\\.(27|28|29|30)$", var.kubernetes_version))
    error_message = "Kubernetes version must be a supported version."
  }
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks that can access the cluster API publicly"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7

  validation {
    condition     = var.log_retention_days >= 1 && var.log_retention_days <= 3653
    error_message = "Log retention must be between 1 and 3653 days."
  }
}

# Node Group Configuration
variable "desired_node_count" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 3

  validation {
    condition     = var.desired_node_count >= 1
    error_message = "Must have at least 1 node."
  }
}

variable "min_node_count" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 2

  validation {
    condition     = var.min_node_count >= 1
    error_message = "Minimum nodes must be at least 1."
  }
}

variable "max_node_count" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 10

  validation {
    condition     = var.max_node_count >= var.desired_node_count
    error_message = "Max nodes must be >= desired nodes."
  }
}

variable "node_instance_types" {
  description = "Instance types for worker nodes"
  type        = list(string)
  default     = ["t3.large"]
}

variable "node_disk_size" {
  description = "Disk size for worker nodes in GB"
  type        = number
  default     = 50

  validation {
    condition     = var.node_disk_size >= 20
    error_message = "Node disk size must be at least 20 GB."
  }
}

variable "node_disk_type" {
  description = "EBS volume type for node disks"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.node_disk_type)
    error_message = "Must be a valid EBS volume type."
  }
}

variable "node_disk_iops" {
  description = "IOPS for EBS volumes"
  type        = number
  default     = 3000
}

variable "node_disk_throughput" {
  description = "Throughput for EBS volumes (gp3 only)"
  type        = number
  default     = 125
}

# Spot Node Group Configuration
variable "create_spot_node_group" {
  description = "Whether to create a spot instance node group"
  type        = bool
  default     = false
}

variable "spot_desired_size" {
  description = "Desired number of spot nodes"
  type        = number
  default     = 1
}

variable "spot_min_size" {
  description = "Minimum number of spot nodes"
  type        = number
  default     = 0
}

variable "spot_max_size" {
  description = "Maximum number of spot nodes"
  type        = number
  default     = 5
}

variable "spot_instance_types" {
  description = "Instance types for spot nodes"
  type        = list(string)
  default     = ["t3.large", "t3a.large", "m5.large", "m6.large"]
}
