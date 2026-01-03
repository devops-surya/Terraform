# VPC-DYNAMIC - Multi-Environment VPC Infrastructure with Terraform Workspaces

Enterprise-grade Terraform configuration for deploying multi-environment AWS VPC infrastructure using workspace-based state management with automatic S3 folder isolation.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Key Strategies](#key-strategies)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Quick Start Guide](#quick-start-guide)
- [Environment Configurations](#environment-configurations)
- [Detailed Usage](#detailed-usage)
- [Backend & State Management](#backend--state-management)
- [VPC Module](#vpc-module)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

This project demonstrates a **production-ready multi-environment VPC deployment** strategy using Terraform workspaces. Each environment (dev, staging, prod) maintains isolated infrastructure with separate state files automatically organized in S3.

### Key Features

✅ **Workspace-Based Isolation** - Separate Terraform workspaces for each environment  
✅ **Automatic S3 Folder Segregation** - State files stored in environment-specific S3 folders  
✅ **DynamoDB State Locking** - Prevents concurrent state modifications  
✅ **Environment-Specific Variables** - Dedicated `.tfvars` files for each environment  
✅ **Reusable VPC Module** - Local module for consistent VPC provisioning  
✅ **Cost Optimization** - Dev uses single NAT, Production uses multi-AZ NAT  
✅ **Workspace Validation** - Built-in checks to prevent wrong environment deployments  

---

## 🏗️ Architecture

### Infrastructure Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         AWS VPC Architecture                            │
│                    (Multi-Environment Deployment)                       │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│  Region: us-east-1                                                      │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ VPC (10.x.0.0/16)                                               │   │
│  │                                                                  │   │
│  │  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐   │   │
│  │  │   AZ-1         │  │   AZ-2         │  │   AZ-3         │   │   │
│  │  │  us-east-1a    │  │  us-east-1b    │  │  us-east-1c    │   │   │
│  │  ├────────────────┤  ├────────────────┤  ├────────────────┤   │   │
│  │  │ Public Subnet  │  │ Public Subnet  │  │ Public Subnet  │   │   │
│  │  │ 10.x.1.0/24    │  │ 10.x.2.0/24    │  │ 10.x.3.0/24    │   │   │
│  │  │                │  │                │  │                │   │   │
│  │  │  ┌──────────┐  │  │  ┌──────────┐  │  │  ┌──────────┐  │   │   │
│  │  │  │NAT GW    │  │  │  │NAT GW    │  │  │  │NAT GW    │  │   │   │
│  │  │  │(EIP)     │  │  │  │(EIP)     │  │  │  │(EIP)     │  │   │   │
│  │  │  └────┬─────┘  │  │  └────┬─────┘  │  │  └────┬─────┘  │   │   │
│  │  ├───────┼────────┤  ├───────┼────────┤  ├───────┼────────┤   │   │
│  │  │       │        │  │       │        │  │       │        │   │   │
│  │  │ Private Subnet │  │ Private Subnet │  │ Private Subnet │   │   │
│  │  │ 10.x.11.0/24   │  │ 10.x.12.0/24   │  │ 10.x.13.0/24   │   │   │
│  │  │       ▲        │  │       ▲        │  │       ▲        │   │   │
│  │  └───────┼────────┘  └───────┼────────┘  └───────┼────────┘   │   │
│  │          │                   │                   │            │   │
│  │          └───────────────────┴───────────────────┘            │   │
│  │                              │                                │   │
│  │                    ┌─────────▼──────────┐                     │   │
│  │                    │ Internet Gateway   │                     │   │
│  │                    └────────────────────┘                     │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘

         ┌──────────────────────────────────────────────┐
         │        Route Table Configuration             │
         ├──────────────────────────────────────────────┤
         │ Public RT:  0.0.0.0/0 → Internet Gateway    │
         │ Private RT: 0.0.0.0/0 → NAT Gateway (per AZ) │
         └──────────────────────────────────────────────┘
```

### Workspace-Based State Isolation

```
S3 Bucket: terraform-state-backend-vpc-dynamic-production-440744235311
│
├── env/
│   ├── dev/
│   │   └── vpc-dynamic/
│   │       └── terraform.tfstate          ← Dev workspace state
│   │           CIDR: 10.10.0.0/16
│   │           NAT: Single (cost-optimized)
│   │
│   ├── staging/
│   │   └── vpc-dynamic/
│   │       └── terraform.tfstate          ← Staging workspace state
│   │           CIDR: 10.20.0.0/16
│   │           NAT: Multi-AZ
│   │
│   └── prod/
│       └── vpc-dynamic/
│           └── terraform.tfstate          ← Prod workspace state
│               CIDR: 10.0.0.0/16
│               NAT: Multi-AZ (Full HA)
│
└── DynamoDB: terraform-state-lock-vpc-dynamic-production
    └── State locking for all workspaces
```

---

## 🎓 Key Strategies

### 1. **Terraform Workspaces for Environment Isolation**

Each environment uses a dedicated Terraform workspace:
- **dev** → Development environment
- **staging** → Pre-production testing
- **prod** → Production workload

**Benefits:**
- Single codebase for all environments
- Workspace-specific state management
- Prevents accidental cross-environment changes

### 2. **S3 Backend with `workspace_key_prefix`**

The critical configuration in `backend.tf`:
```hcl
workspace_key_prefix = "env"
```

This automatically creates separate S3 folders:
- `env/dev/` for dev workspace
- `env/staging/` for staging workspace
- `env/prod/` for prod workspace

**Benefits:**
- Automatic state file isolation
- Clear organization in S3
- No manual path management

### 3. **Environment-Specific Variable Files**

Each environment has its own `.tfvars` file:
- `environments/dev.tfvars`
- `environments/staging.tfvars`
- `environments/prod.tfvars`

**Important:** Variables are NOT automatically loaded. You must specify them manually:
```bash
terraform apply -var-file="environments/dev.tfvars"
```

### 4. **Reusable VPC Module**

Local module in `./vpc-module/` provides:
- Consistent VPC configuration
- Reusable across environments
- Easy to customize per environment

### 5. **Workspace-Aware Configuration**

`main.tf` includes workspace validation:
```hcl
locals {
  allowed_workspaces = ["dev", "staging", "prod"]
  is_valid_workspace = contains(local.allowed_workspaces, terraform.workspace)
}
```

Prevents deployment to unauthorized workspaces.

---

## 📁 Project Structure

```
VPC-DYNAMIC/
├── backend.tf                 # S3 backend with workspace_key_prefix
├── provider.tf                # AWS provider configuration
├── main.tf                    # VPC module usage with workspace validation
├── variables.tf               # Input variable definitions
├── outputs.tf                 # Output definitions
├── terraform.tfvars.example   # Example variables file
├── README.md                  # This file
├── WORKFLOW.md                # Detailed workflow diagrams
│
├── environments/              # Environment-specific configurations
│   ├── dev.tfvars            # Dev: 10.10.0.0/16, single NAT
│   ├── staging.tfvars        # Staging: 10.20.0.0/16, multi-AZ NAT
│   └── prod.tfvars           # Prod: 10.0.0.0/16, multi-AZ NAT
│
├── vpc-module/                # Reusable VPC module
│   ├── vpc.tf                # VPC, subnets, NAT, routing resources
│   ├── variables.tf          # Module input variables
│   ├── outputs.tf            # Module outputs
│   ├── versions.tf           # Provider version constraints
│   └── README.md             # Module documentation
│
└── state-backend/             # Backend infrastructure setup
    ├── main.tf               # S3 bucket & DynamoDB table
    ├── outputs.tf
    ├── provider.tf
    └── variables.tf
```

---

## ✅ Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0 installed
3. **AWS CLI** configured with credentials
4. **S3 Backend** already created (in `state-backend/`)
5. **DynamoDB Table** for state locking

### Verify Setup

```bash
# Check Terraform version
terraform version

# Check AWS credentials
aws sts get-caller-identity

# Verify S3 bucket exists
aws s3 ls s3://terraform-state-backend-vpc-dynamic-production-440744235311
```

---

## 🚀 Quick Start Guide

### Step 1: Initialize Backend

```bash
cd VPC-DYNAMIC
terraform init
```

This configures the S3 backend and downloads required providers.

### Step 2: Create Workspace

```bash
# Create and switch to dev workspace
terraform workspace new dev

# Or select existing workspace
terraform workspace select dev

# Verify current workspace
terraform workspace show
```

### Step 3: Plan Infrastructure

```bash
terraform plan -var-file="environments/dev.tfvars"
```

Review the plan output carefully.

### Step 4: Deploy Infrastructure

```bash
terraform apply -var-file="environments/dev.tfvars"
```

Type `yes` when prompted.

### Step 5: Verify Deployment

```bash
# View outputs
terraform output

# List deployed resources
terraform state list
```

---

## 📋 Environment Configurations

### Development Environment

**File:** `environments/dev.tfvars`

```hcl
vpc_cidr             = "10.10.0.0/16"
public_subnet_cidrs  = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
private_subnet_cidrs = ["10.10.11.0/24", "10.10.12.0/24", "10.10.13.0/24"]
single_nat_gateway   = true  # Cost optimization
```

**Characteristics:**
- Lower cost (single NAT Gateway)
- 10.10.0.0/16 CIDR range
- Suitable for development/testing

### Staging Environment

**File:** `environments/staging.tfvars`

```hcl
vpc_cidr             = "10.20.0.0/16"
public_subnet_cidrs  = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]
private_subnet_cidrs = ["10.20.11.0/24", "10.20.12.0/24", "10.20.13.0/24"]
single_nat_gateway   = false  # Multi-AZ NAT
```

**Characteristics:**
- Medium cost (NAT per AZ)
- 10.20.0.0/16 CIDR range
- Pre-production testing environment

### Production Environment

**File:** `environments/prod.tfvars`

```hcl
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
single_nat_gateway   = false  # Full HA
```

**Characteristics:**
- Full high availability
- 10.0.0.0/16 CIDR range
- Production workloads

| Feature | Dev | Staging | Prod |
|---------|-----|---------|------|
| VPC CIDR | 10.10.0.0/16 | 10.20.0.0/16 | 10.0.0.0/16 |
| NAT Gateways | 1 | 3 | 3 |
| High Availability | ❌ | ⚠️ Partial | ✅ Full |
| Cost | 💰 Low | 💰💰 Medium | 💰💰💰 High |

---

## 📖 Detailed Usage

### Complete Workflow for Each Environment

#### Deploy Development

```bash
# 1. Initialize (first time only)
terraform init

# 2. Create/Select workspace
terraform workspace new dev

# 3. Plan changes
terraform plan -var-file="environments/dev.tfvars" -out=dev.tfplan

# 4. Apply changes
terraform apply dev.tfplan

# 5. View outputs
terraform output
```

#### Deploy Staging

```bash
# Switch to staging workspace
terraform workspace select staging

# Plan and apply
terraform plan -var-file="environments/staging.tfvars"
terraform apply -var-file="environments/staging.tfvars"
```

#### Deploy Production

```bash
# Switch to production workspace
terraform workspace select prod

# Plan (ALWAYS plan first for production!)
terraform plan -var-file="environments/prod.tfvars" -out=prod.tfplan

# Review plan carefully, then apply
terraform apply prod.tfplan
```

### Destroy Infrastructure

```bash
# Switch to target workspace
terraform workspace select dev

# Destroy resources
terraform destroy -var-file="environments/dev.tfvars"
```

### Workspace Management Commands

```bash
# List all workspaces
terraform workspace list

# Show current workspace
terraform workspace show

# Create new workspace
terraform workspace new <name>

# Switch workspace
terraform workspace select <name>

# Delete workspace (must be empty)
terraform workspace delete <name>
```

---

## 🔧 Backend & State Management

### Backend Configuration

**File:** `backend.tf`

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-backend-vpc-dynamic-production-440744235311"
    key            = "vpc-dynamic/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock-vpc-dynamic-production"
    encrypt        = true
    workspace_key_prefix = "env"  # Critical for folder isolation
  }
}
```

### State File Paths

| Workspace | S3 Path |
|-----------|---------|
| **default** | `vpc-dynamic/terraform.tfstate` |
| **dev** | `env/dev/vpc-dynamic/terraform.tfstate` |
| **staging** | `env/staging/vpc-dynamic/terraform.tfstate` |
| **prod** | `env/prod/vpc-dynamic/terraform.tfstate` |

### DynamoDB State Locking

**Table:** `terraform-state-lock-vpc-dynamic-production`

Prevents concurrent state modifications:
- LockID format: `<bucket>/<path>`
- Automatically acquires/releases locks
- Prevents race conditions

---

## 🧩 VPC Module

The local VPC module (`./vpc-module/`) creates:

### Resources Created

- **1 VPC** with DNS support enabled
- **3 Public Subnets** (one per AZ)
- **3 Private Subnets** (one per AZ)
- **1 Internet Gateway**
- **1-3 NAT Gateways** (configurable)
- **3 Elastic IPs** (for NAT Gateways)
- **1 Public Route Table**
- **3 Private Route Tables** (one per AZ)
- **Route Table Associations**

### Module Usage

```hcl
module "vpc" {
  source = "./vpc-module"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}
```

### Module Outputs

All outputs are available via:

```bash
terraform output vpc_id
terraform output nat_gateway_ips
terraform output private_subnet_ids
```

---

## 🎯 Best Practices

### 1. Always Verify Workspace

```bash
# Before any operation
terraform workspace show

# Ensure it matches your intent
```

### 2. Use Plan Files for Production

```bash
terraform plan -var-file="environments/prod.tfvars" -out=prod.tfplan
# Review plan thoroughly
terraform apply prod.tfplan
```

### 3. Never Mix Workspaces and Variables

❌ **WRONG:**
```bash
terraform workspace select prod
terraform apply -var-file="environments/dev.tfvars"  # DANGER!
```

✅ **CORRECT:**
```bash
terraform workspace select prod
terraform apply -var-file="environments/prod.tfvars"  # Correct match
```

### 4. State File Safety

- ✅ Never commit `.tfstate` files to Git
- ✅ Always use remote backend (S3)
- ✅ Enable versioning on S3 bucket
- ✅ Enable state locking with DynamoDB

### 5. Environment Promotion Flow

```
Dev → Validate → Staging → Test → Production
```

Always promote changes through environments sequentially.

### 6. Tag Everything

All resources are automatically tagged with:
- `Project`: from variables
- `Environment`: from workspace
- `ManagedBy`: Terraform

---

## 🛠️ Troubleshooting

### Backend Not Initialized

**Error:** `Backend configuration not initialized`

**Solution:**
```bash
terraform init
```

### Wrong Workspace Selected

**Error:** Applied changes to wrong environment

**Prevention:**
```bash
# Always check before operations
terraform workspace show

# If wrong, switch immediately
terraform workspace select <correct-workspace>
```

### State Lock Issues

**Error:** `Error acquiring the state lock`

**Solution:**
```bash
# Check who has the lock (review carefully)
# If safe to unlock:
terraform force-unlock <LOCK_ID>
```

### Variable File Not Found

**Error:** `var-file not found`

**Solution:**
```bash
# Use correct path
terraform apply -var-file="environments/dev.tfvars"

# Check file exists
ls environments/
```

### Workspace Doesn't Exist

**Error:** `Workspace doesn't exist`

**Solution:**
```bash
# Create the workspace first
terraform workspace new dev
```

### View Current State

```bash
# Show all resources
terraform state list

# Show specific resource
terraform state show module.vpc.aws_vpc.main

# View outputs
terraform output
```

### Refresh State

```bash
# Sync state with actual infrastructure
terraform refresh -var-file="environments/dev.tfvars"
```

---

## 📚 Additional Resources

- [Terraform Workspaces Documentation](https://www.terraform.io/docs/language/state/workspaces.html)
- [S3 Backend Configuration](https://www.terraform.io/docs/language/settings/backends/s3.html)
- [AWS VPC Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html)
- [WORKFLOW.md](WORKFLOW.md) - Detailed workflow diagrams

---

## 🔑 Quick Reference Card

```bash
# Initialize
terraform init

# Workspace Management
terraform workspace new dev
terraform workspace select prod
terraform workspace list
terraform workspace show

# Deployment
terraform plan -var-file="environments/<env>.tfvars"
terraform apply -var-file="environments/<env>.tfvars"
terraform destroy -var-file="environments/<env>.tfvars"

# Validation
terraform validate
terraform fmt -check

# State Management
terraform state list
terraform output
terraform refresh -var-file="environments/<env>.tfvars"
```

---

## ⚠️ Important Reminders

1. **Workspace ≠ Automatic Variables**
   - Switching workspace ONLY changes where state is stored
   - You MUST manually specify the correct `.tfvars` file

2. **Always Double-Check**
   ```bash
   terraform workspace show  # Verify workspace
   # Then specify matching tfvars
   ```

3. **State Location**
   - Workspace determines S3 folder
   - `workspace_key_prefix = "env"` handles this automatically

4. **Backend Must Exist**
   - Run `state-backend/` configuration first
   - S3 bucket and DynamoDB table must be created

---

**Last Updated:** January 3, 2026  
**Terraform Version:** >= 1.0  
**AWS Provider:** ~> 5.0
