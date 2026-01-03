# Staging Environment Variables
# Usage: terraform apply -var-file="environments/staging.tfvars"

aws_region   = "us-east-1"
project_name = "my-project-stagging"
environment  = "staging"

# VPC Configuration
vpc_cidr             = "10.20.0.0/16"
public_subnet_cidrs  = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]
private_subnet_cidrs = ["10.20.11.0/24", "10.20.12.0/24", "10.20.13.0/24"]

# Staging-specific settings
enable_nat_gateway = true
single_nat_gateway = false  # Use NAT per AZ for staging (partial HA)

# Tags specific to staging
additional_tags = {
  CostCenter = "Engineering"
  Team       = "DevOps"
  Purpose    = "Staging"
}
