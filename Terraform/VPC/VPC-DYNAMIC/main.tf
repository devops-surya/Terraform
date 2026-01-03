# Locals for workspace-aware configuration
locals {
  # Get current workspace name
  workspace = terraform.workspace
  
  # Validate workspace is one of the allowed environments
  allowed_workspaces = ["dev", "staging", "prod"]
  is_valid_workspace = contains(local.allowed_workspaces, local.workspace)
  
  # Workspace-specific configurations
  workspace_config = {
    dev = {
      instance_size = "small"
      ha_enabled    = false
    }
    staging = {
      instance_size = "medium"
      ha_enabled    = true
    }
    prod = {
      instance_size = "large"
      ha_enabled    = true
    }
  }
  
  # Get current workspace config
  current_config = local.workspace_config[local.workspace]
  
  # Common tags that include workspace
  common_tags = merge(
    var.additional_tags,
    {
      Workspace   = local.workspace
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

# Validate that we're using an allowed workspace
resource "null_resource" "workspace_validation" {
  lifecycle {
    precondition {
      condition     = local.is_valid_workspace
      error_message = "Invalid workspace '${local.workspace}'. Allowed workspaces: ${join(", ", local.allowed_workspaces)}"
    }
  }
}

# VPC Module with workspace-aware configuration
module "vpc" {
  source = "./vpc-module"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}
