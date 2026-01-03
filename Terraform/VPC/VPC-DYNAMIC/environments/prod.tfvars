# Production Environment Variables
# Usage: terraform apply -var-file="environments/prod.tfvars"

aws_region   = "us-east-1"
project_name = "my-project-prod"
environment  = "prod"

# VPC Configuration
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

# Production-specific settings
enable_nat_gateway = true
single_nat_gateway = false  # Use NAT per AZ for full HA

# Tags specific to production
additional_tags = {
  CostCenter  = "Production"
  Team        = "DevOps"
  Purpose     = "Production"
  Compliance  = "Required"
  Criticality = "High"
}
