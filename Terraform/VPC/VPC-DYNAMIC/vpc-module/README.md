# VPC Terraform Module

This is a reusable VPC module for creating AWS VPC infrastructure with public and private subnets across multiple availability zones.

## Features

- VPC with configurable CIDR block
- Public subnets with Internet Gateway
- Private subnets with NAT Gateways
- Multi-AZ deployment
- Customizable subnet configurations

## Usage

```hcl
module "vpc" {
  source = "./vpc-module"

  project_name = "my-project"
  environment  = "dev"
  aws_region   = "us-east-1"

  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| aws_region | AWS region | string | us-east-1 |
| project_name | Project name for resource naming | string | my-project |
| environment | Environment name | string | production |
| vpc_cidr | CIDR block for VPC | string | 10.0.0.0/16 |
| public_subnet_cidrs | List of CIDR blocks for public subnets | list(string) | ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"] |
| private_subnet_cidrs | List of CIDR blocks for private subnets | list(string) | ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"] |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | VPC ID |
| vpc_cidr | VPC CIDR block |
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private subnet IDs |
| nat_gateway_ids | List of NAT Gateway IDs |
| nat_gateway_ips | List of NAT Gateway public IPs |
| internet_gateway_id | Internet Gateway ID |
