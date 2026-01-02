# VPC Terraform Module

A reusable Terraform module for creating a production-ready AWS VPC infrastructure with high availability and cost optimization measures.

## Features

- **Multi-AZ Deployment**: Public and private subnets across multiple availability zones
- **NAT Gateways**: One NAT gateway per availability zone for private subnet internet access
- **Internet Gateway**: Single IGW for public internet connectivity
- **Route Tables**: Separate route tables for public and private subnets
- **High Availability**: Fault-tolerant architecture across multiple AZs
- **Cost Optimized**: Efficient NAT gateway placement and resource tagging

## Architecture

The module creates:
- 1 VPC with DNS support enabled
- 1 Internet Gateway
- 3 Public Subnets (one per AZ)
- 3 Private Subnets (one per AZ)
- 3 NAT Gateways with Elastic IPs (one per AZ)
- 1 Public Route Table
- 3 Private Route Tables (one per AZ)

## Usage

### Basic Example

```hcl
module "vpc" {
  source = "../vpc-module"

  project_name = "my-project"
  environment  = "production"
  aws_region   = "us-east-1"
  
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}
```

### Complete Example with Provider

```hcl
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  
  default_tags {
    tags = {
      Project     = "my-project"
      Environment = "production"
      ManagedBy   = "Terraform"
    }
  }
}

module "vpc" {
  source = "../vpc-module"

  project_name = "my-project"
  environment  = "production"
  aws_region   = "us-east-1"
  
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

# Use module outputs
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws_region | AWS region for deployment | `string` | `"us-east-1"` | no |
| project_name | Project name for resource naming | `string` | `"my-project"` | no |
| environment | Environment name | `string` | `"production"` | no |
| vpc_cidr | CIDR block for VPC | `string` | `"10.0.0.0/16"` | no |
| public_subnet_cidrs | CIDR blocks for public subnets | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]` | no |
| private_subnet_cidrs | CIDR blocks for private subnets | `list(string)` | `["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | VPC ID |
| vpc_cidr | VPC CIDR block |
| public_subnet_ids | List of public subnet IDs |
| public_subnet_cidrs | List of public subnet CIDR blocks |
| private_subnet_ids | List of private subnet IDs |
| private_subnet_cidrs | List of private subnet CIDR blocks |
| nat_gateway_ids | List of NAT Gateway IDs |
| nat_gateway_ips | List of NAT Gateway public IPs (Elastic IPs) |
| internet_gateway_id | Internet Gateway ID |
| public_route_table_id | Public Route Table ID |
| private_route_table_ids | List of Private Route Table IDs |

## Examples

See the `../vpcmodule-usage` directory for complete working examples.

## Notes

- The module automatically selects available AZs using `data.aws_availability_zones`
- All resources are tagged with Project, Environment, and ManagedBy tags (via provider default_tags)
- NAT gateways are placed in public subnets, one per availability zone
- Private subnets route outbound traffic through their respective NAT gateways

## Cost Estimation

Approximate monthly costs:
- VPC: Free
- Subnets: Free
- Internet Gateway: Free
- Elastic IPs (attached): Free
- NAT Gateways (3x): ~$97/month
- Data Processing: ~$0.05/GB

**Total: ~$97/month** (excluding data transfer costs)

## License

Internal use only
