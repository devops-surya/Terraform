# Backend configuration with Terraform Workspace support
# Each workspace (dev, staging, prod) stores state in separate S3 path
#
# State path structure:
# - default workspace: terraform.tfstate
# - dev workspace: env/dev/terraform.tfstate
# - staging workspace: env/staging/terraform.tfstate
# - prod workspace: env/prod/terraform.tfstate

terraform {
  backend "s3" {
    bucket         = "tfstate-vpc-dynamic-production-440744235311"
    key            = "vpc-dynamic/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tfstate-lock-vpc-dynamic-production"
    encrypt        = true
    
    # Workspace prefix enables separate state files per workspace
    # This automatically creates: env/dev/, env/staging/, env/prod/ folders
    workspace_key_prefix = "env"
  }
}

# Workspace Management Commands:
# ================================
# terraform workspace list                    # List all workspaces
# terraform workspace new dev                 # Create dev workspace
# terraform workspace new staging             # Create staging workspace
# terraform workspace new prod                # Create prod workspace
# terraform workspace select dev              # Switch to dev workspace
# terraform workspace show                    # Show current workspace
#
# Usage:
# terraform workspace select dev
# terraform apply -var-file="environments/dev.tfvars"
#
# terraform workspace select staging
# terraform apply -var-file="environments/staging.tfvars"
#
# terraform workspace select prod
# terraform apply -var-file="environments/prod.tfvars"
