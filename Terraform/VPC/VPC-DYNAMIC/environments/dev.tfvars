# Development Environment Variables
# Usage: terraform apply -var-file="environments/dev.tfvars"

aws_region   = "us-east-1"
project_name = "my-project-dev"
environment  = "dev"

# VPC Configuration
vpc_cidr             = "10.10.0.0/16"
public_subnet_cidrs  = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
private_subnet_cidrs = ["10.10.11.0/24", "10.10.12.0/24", "10.10.13.0/24"]

# Development-specific settings
enable_nat_gateway = true  # Can be false to save costs in dev
single_nat_gateway = true  # Use single NAT for dev to save costs

# Tags specific to development
additional_tags = {
  CostCenter = "Engineering"
  Team       = "DevOps"
  Purpose    = "Development"
}
