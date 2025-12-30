# VPC-Only Terraform Configuration

## Overview

This Terraform configuration creates a production-ready AWS VPC infrastructure with high availability and cost optimization measures. The setup includes public and private subnets across multiple availability zones with NAT gateways for private subnet internet access.

---

## Architecture

### Network Design
- **VPC CIDR**: 10.0.0.0/16
- **Public Subnets**: 3 subnets (10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24)
- **Private Subnets**: 3 subnets (10.0.11.0/24, 10.0.12.0/24, 10.0.13.0/24)
- **Availability Zones**: Distributed across 3 AZs for redundancy

---

## Key Infrastructure Components

### 1. **VPC (Virtual Private Cloud)**
- DNS hostnames enabled for EC2 instances
- DNS support enabled for AWS service communication

### 2. **Internet Gateway**
- Provides internet connectivity for public subnets
- Attached to VPC for routing 0.0.0.0/0 traffic

### 3. **Subnets**
- **Public Subnets**: Auto-assign public IPs enabled for internet-facing resources
- **Private Subnets**: No public IP assignment; access internet through NAT gateways

### 4. **NAT Gateways**
- One NAT gateway per availability zone
- Elastic IPs allocated for each NAT gateway
- Enables outbound internet access for private resources

### 5. **Route Tables**
- **Public Route Table**: Routes 0.0.0.0/0 to Internet Gateway
- **Private Route Tables**: Routes 0.0.0.0/0 to respective NAT gateways

---

## High Availability Measures

### 1. **Multi-AZ Deployment**
- **3 Availability Zones**: Public and private subnets distributed across 3 AZs
- **Benefit**: Tolerates single AZ failure without service disruption
- **Implementation**: Uses `data.aws_availability_zones` to automatically select available AZs

### 2. **NAT Gateway Redundancy**
- **One NAT gateway per AZ**: Each private subnet's AZ has its dedicated NAT gateway
- **Benefit**: If one NAT gateway fails, only resources in that AZ are affected
- **Independent Elastic IPs**: Each NAT gateway has its own Elastic IP

### 3. **Isolated Network Layers**
- **Public/Private Separation**: Public resources (web tier) separate from private resources (database/backend)
- **Benefit**: Reduces attack surface and improves security posture

### 4. **Elastic IPs**
- **Static Public IPs**: NAT gateways use Elastic IPs for consistent outbound IP addresses
- **Benefit**: External services can rely on consistent IP addresses for whitelisting

---

## Cost Optimization Methods

### 1. **NAT Gateway Cost Efficiency**
- **Single NAT per AZ**: Instead of one per subnet, reducing costs significantly
- **Cost Breakdown**:
  - NAT Gateway hourly charge: ~$0.045/hour per gateway
  - Data processing: ~$0.045/GB processed
  - 3 NAT gateways = ~$97/month (3 × 24 × 30 × $0.045)
- **Optimization**: Consolidating to fewer NAT gateways per AZ

### 2. **Elastic IP Management**
- **Attached EIPs**: Only charged when actively attached to NAT gateways
- **Benefit**: No charge for unused IPs when not associated with resources

### 3. **VPC Endpoints (Future Enhancement)**
- Can add S3/DynamoDB gateway endpoints to reduce NAT gateway data transfer costs
- Suggested for high-volume S3/DynamoDB access

### 4. **Network Design Efficiency**
- **Proper CIDR Planning**: /24 subnets provide 251 usable IPs, balancing availability and waste
- **Single VPC**: Consolidates resources, reducing management overhead
- **No unnecessary NAT**: Private subnets route only necessary traffic through NAT

### 5. **Automatic Resource Tagging**
- **Default Tags**: Project, Environment, and ManagedBy tags applied automatically
- **Benefit**: Easy cost allocation and tracking via AWS Cost Explorer

---

## Cost Estimation

### Monthly Breakdown (Approximate)
| Resource | Quantity | Cost/Month |
|----------|----------|-----------|
| VPC | 1 | Free |
| Subnets | 6 | Free |
| Internet Gateway | 1 | Free |
| Elastic IPs | 3 | $0 (attached) |
| NAT Gateways | 3 | ~$97 |
| Data Processing (est.) | 1GB/month | ~$0.05 |
| **Total** | | **~$97/month** |

*Note: Costs vary by region and actual data transfer. This is a baseline estimate.*

---

## File Structure

```
VPC-Only/
├── vpc.tf              # Main VPC, subnets, NAT gateways, route tables
├── variables.tf        # Input variables and defaults
├── outputs.tf          # Output values for integration with other modules
├── provider.tf         # AWS provider configuration
├── terraform.tfvars    # Variable values
└── README.md          # This file
```

---

## Prerequisites

- AWS Account with appropriate permissions
- Terraform >= 1.0
- AWS CLI configured (optional, for state management)

---

## Usage

### 1. Initialize Terraform
```bash
terraform init
```

### 2. Plan the deployment
```bash
terraform plan -out=tfplan
```

### 3. Apply the configuration
```bash
terraform apply tfplan
```

### 4. View outputs
```bash
terraform output
```

### 5. Destroy resources
```bash
terraform destroy
```

---

## Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `aws_region` | string | us-east-1 | AWS region for deployment |
| `project_name` | string | my-project | Project name for resource naming |
| `environment` | string | production | Environment name |
| `vpc_cidr` | string | 10.0.0.0/16 | VPC CIDR block |
| `public_subnet_cidrs` | list(string) | ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"] | Public subnet CIDRs |
| `private_subnet_cidrs` | list(string) | ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"] | Private subnet CIDRs |

---

## Outputs

- `vpc_id`: VPC identifier
- `vpc_cidr`: VPC CIDR block
- `public_subnet_ids`: IDs of public subnets
- `private_subnet_ids`: IDs of private subnets
- `nat_gateway_ids`: IDs of NAT gateways
- `nat_gateway_ips`: Public IP addresses of NAT gateways
- `internet_gateway_id`: Internet Gateway ID
- `public_route_table_id`: Public route table ID
- `private_route_table_ids`: Private route table IDs

---

## Security Considerations

1. **Network Segmentation**: Public and private subnets provide network isolation
2. **Outbound Control**: Private resources access internet only through NAT gateways
3. **Inbound Protection**: Private subnets have no direct inbound internet access
4. **Tagging Strategy**: Resources tagged for access control and cost tracking

---

## Future Enhancements

1. **VPC Flow Logs**: Enable for monitoring and troubleshooting
2. **VPC Endpoints**: Add S3/DynamoDB gateway endpoints for cost optimization
3. **Bastion Host**: Add in public subnet for secure private resource access
4. **AWS Systems Manager Session Manager**: Replace bastion for secure access
5. **CloudWatch Monitoring**: Add alarms for NAT gateway bandwidth/connections
6. **Network ACLs**: Additional layer of security for subnet-level control

---

## Maintenance & Support

- **State Management**: Ensure Terraform state files are backed up and version controlled
- **Cost Monitoring**: Review AWS Cost Explorer monthly for unexpected charges
- **Scaling**: Add subnets by extending the subnet CIDR lists in terraform.tfvars
- **Updates**: Keep AWS provider version updated for latest features and security patches

---

## License

Internal use only

---

## Contact

For questions or modifications, refer to the infrastructure team.
