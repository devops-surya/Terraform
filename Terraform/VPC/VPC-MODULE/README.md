# Terraform Modules

This directory contains reusable Terraform modules for AWS infrastructure.

## Available Modules

### VPC Module (`vpc-module/`)

A production-ready VPC module that creates:
- Multi-AZ VPC with public and private subnets
- Internet Gateway for public access
- NAT Gateways (one per AZ) for private subnet internet access
- Route tables for proper traffic routing

**Location:** `vpc-module/`

**Documentation:** [VPC Module README](vpc-module/README.md)

**Example Usage:** [VPC Module Usage](vpcmodule-usage/)

## Module Structure

```
MODULE/
├── vpc-module/          # VPC Terraform module
│   ├── vpc.tf          # VPC resources
│   ├── variables.tf    # Module inputs
│   ├── outputs.tf      # Module outputs
│   ├── versions.tf     # Terraform and provider requirements
│   └── README.md       # Module documentation
│
└── vpcmodule-usage/     # Example showing how to use the VPC module
    ├── provider.tf     # Terraform and AWS provider configuration
    ├── main.tf         # Module usage example
    ├── variables.tf    # Input variables
    ├── outputs.tf      # Output values
    ├── terraform.tfvars.example  # Example variable values
    └── README.md       # Usage instructions
```

## How to Use a Module

### 1. Basic Usage

```hcl
module "vpc" {
  source = "./MODULE/vpc-module"

  project_name = "my-project"
  environment  = "production"
  aws_region   = "us-east-1"
  
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}
```

### 2. Using Module Outputs

```hcl
# Access module outputs
output "vpc_id" {
  value = module.vpc.vpc_id
}

# Use outputs in other resources
resource "aws_instance" "web" {
  subnet_id = module.vpc.public_subnet_ids[0]
  # ... other configuration
}
```

### 3. Complete Example

See the `vpcmodule-usage/` directory for a complete working example.

## Module Development Guidelines

When creating new modules:

1. **No Provider Configuration**: Modules should not contain `provider` blocks. Providers are configured in the root module.

2. **Version Requirements**: Include `versions.tf` with Terraform and provider version requirements.

3. **Documentation**: Each module should have a comprehensive README.md with:
   - Description and features
   - Usage examples
   - Input variables table
   - Outputs table
   - Requirements

4. **Variables**: Use descriptive variable names with defaults where appropriate.

5. **Outputs**: Expose all important resource IDs and attributes as outputs.

6. **Tags**: Use provider-level default tags rather than module-level tags.

## Best Practices

- **Reusability**: Design modules to be reusable across different projects
- **Flexibility**: Provide variables for customization
- **Documentation**: Keep documentation up to date
- **Testing**: Test modules in isolation before using in production
- **Versioning**: Consider versioning modules for production use

## Examples

### Using VPC Module in EKS Setup

```hcl
# Use VPC module
module "vpc" {
  source = "../MODULE/vpc-module"
  # ... configuration
}

# Use VPC outputs in EKS
module "eks" {
  source = "../EKS"
  
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
}
```

## Contributing

When adding new modules:

1. Create a new directory under `MODULE/`
2. Follow the module structure guidelines
3. Include comprehensive documentation
4. Add an example usage in `vpcmodule-usage/` or create a new example directory
5. Update this README with the new module information

---

## S3 Bucket & DynamoDB Security Strategies

### S3 Bucket Protection Strategies

The `state-backend` directory contains production-ready configurations for Terraform state management. This section documents all security and operational strategies implemented:

#### 1. **Disable Public Access (Block Public Access)**

```hcl
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  block_public_acls       = true    # Prevents ACLs from making bucket public
  block_public_policy     = true    # Prevents bucket policies from making it public
  ignore_public_acls      = true    # Ignores existing public ACLs
  restrict_public_buckets = true    # Restricts public bucket access
}
```

**Benefits:**
- ✅ Prevents accidental public exposure of sensitive state files
- ✅ Blocks all forms of public access regardless of ACL or policy
- ✅ Default deny approach for maximum security
- ✅ Protects against misconfiguration

---

#### 2. **Enable Versioning**

```hcl
resource "aws_s3_bucket_versioning" "terraform_state" {
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}
```

**Benefits:**
- ✅ Keeps history of all state file changes
- ✅ Allows rollback to previous infrastructure states
- ✅ Audit trail for infrastructure modifications
- ✅ Protection against accidental deletions

**Use Cases:**
- Recovering from a failed Terraform apply
- Analyzing what changed between two time periods
- Restoring to a known-good state if corruption occurs

---

#### 3. **Server-Side Encryption (SSE-S3)**

```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"  # AWS-managed encryption keys
    }
  }
}
```

**Benefits:**
- ✅ Encrypts data at rest automatically
- ✅ AWS manages encryption keys (no key management overhead)
- ✅ Transparent to Terraform (automatic encryption/decryption)
- ✅ Compliant with security standards (PCI-DSS, HIPAA, etc.)

---

#### 4. **Lifecycle Policy (Auto-Delete Old Versions)**

```hcl
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  rule {
    id     = "delete_old_versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90  # Delete versions older than 90 days
    }
  }
}
```

**Benefits:**
- ✅ Automatically deletes old state file versions after 90 days
- ✅ Reduces storage costs over time
- ✅ Keeps only recent versions for rollback purposes
- ✅ Prevents unlimited storage growth

**Cost Savings Example:**
- 1 state file change per day × 365 days = 365 versions/year
- With lifecycle (90 days): max 90 files, automatic cleanup
- **Estimated annual savings: $8-15 per bucket**

---

#### 5. **Force Destroy on Terraform Destroy**

```hcl
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "terraform-state-backend-vpcmodule-production-${account_id}"
  force_destroy = true  # Allows terraform destroy to delete bucket even if not empty
}
```

**Benefits:**
- ✅ Allows clean teardown of infrastructure
- ✅ Prevents "bucket not empty" errors during destroy
- ✅ Automatic cleanup of all versions and objects

**When to Use:**
- Development/testing environments
- Temporary infrastructure

**When NOT to Use:**
- Production environments
- Long-term state buckets

---

#### 6. **DynamoDB State Locking**

```hcl
resource "aws_dynamodb_table" "terraform_lock" {
  name           = "terraform-state-lock-vpcmodule-production"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }
}
```

**Lock Mechanism:**
- ✅ Prevents concurrent Terraform applies
- ✅ One user at a time can modify infrastructure
- ✅ Automatic lock timeout (5 minutes default)
- ✅ Maintains lock information (who, when, why)

**DynamoDB Features:**
- **Pay-per-request billing**: Only pay for lock operations, not capacity
- **Point-in-time recovery**: Restore locks if corrupted
- **Server-side encryption**: Lock data encrypted at rest

---

### Security Architecture

```
┌─────────────────────────────────────────────────────────┐
│             TERRAFORM STATE BACKEND SECURITY             │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Layer 1: PUBLIC ACCESS PREVENTION                      │
│  └─ Block Public ACLs          ✅ Enforced             │
│  └─ Block Public Policies       ✅ Enforced             │
│                                                         │
│  Layer 2: DATA PROTECTION AT REST                       │
│  └─ Server-Side Encryption      ✅ AES-256              │
│                                                         │
│  Layer 3: DATA INTEGRITY & RECOVERY                     │
│  └─ Versioning                  ✅ Enabled              │
│  └─ Lifecycle Policies          ✅ 90-day retention     │
│                                                         │
│  Layer 4: CONCURRENCY CONTROL                           │
│  └─ State Locking               ✅ DynamoDB             │
│                                                         │
│  Layer 5: OPERATIONAL SAFETY                            │
│  └─ Force Destroy Option        ✅ Clean teardown       │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## License

Internal use only

