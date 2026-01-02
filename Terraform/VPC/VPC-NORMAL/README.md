# VPC-Only Terraform Configuration

## Overview

This Terraform configuration creates a production-ready AWS VPC infrastructure with high availability and cost optimization measures. The setup includes public and private subnets across multiple availability zones with NAT gateways for private subnet internet access.

---

## Architecture

### Architecture Diagram

**📊 [View VPC Architecture Diagram](VPC_Architecture_Diagram_Clear.drawio)**

> **How to View:**
> - **On GitHub**: Click the link above - GitHub will render the `.drawio` file directly in the browser
> - **Interactive Editing**: Open with [draw.io](https://app.diagrams.net/) or use the [VS Code draw.io extension](https://marketplace.visualstudio.com/items?itemName=hediet.vscode-drawio)
> - **Offline**: Download and open with [draw.io Desktop](https://github.com/jgraph/drawio-desktop/releases)
>
> The diagram illustrates a production-ready multi-AZ VPC architecture with:
> - 3 Availability Zones (us-east-1a, us-east-1b, us-east-1c)
> - 3 Public Subnets (10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24)
> - 3 Private Subnets (10.0.11.0/24, 10.0.12.0/24, 10.0.13.0/24)
> - 3 NAT Gateways (one per AZ) with Elastic IPs
> - Internet Gateway for public internet access
> - Route tables showing traffic flow patterns

**Text-Based Diagram:**

```
                                       INTERNET
                                      (0.0.0.0/0)
                                          |
                                          |
                        ┌─────────────────▼──────────────────┐
                        │   Internet Gateway (1x)            │
                        │   • Single IGW per VPC             │
                        │   • Provides public route target    │
                        └─────────────────┬──────────────────┘
                                          |
                                          | 0.0.0.0/0 route
                                          |
                    ┌─────────────────────┴─────────────────────┐
                    │    Public Route Table                      │
                    │    • Route: 0.0.0.0/0 → IGW               │
                    │    • Associated with all public subnets    │
                    └─────────────────────┬─────────────────────┘
                                          |
                  ┌───────────────────────┼───────────────────────┐
                  │                       │                       │
        ┌─────────▼──────────┐  ┌─────────▼──────────┐  ┌────────▼─────────┐
        │  AZ: us-east-1a    │  │  AZ: us-east-1b    │  │  AZ: us-east-1c  │
        ├────────────────────┤  ├────────────────────┤  ├──────────────────┤
        │                    │  │                    │  │                  │
        │  Public Subnet     │  │  Public Subnet     │  │  Public Subnet   │
        │  10.0.1.0/24       │  │  10.0.2.0/24       │  │  10.0.3.0/24     │
        │  (251 IPs)         │  │  (251 IPs)         │  │  (251 IPs)       │
        │                    │  │                    │  │                  │
        │  Resources:        │  │  Resources:        │  │  Resources:      │
        │  • ALB             │  │  • ALB             │  │  • ALB           │
        │  • NAT Gateway     │  │  • NAT Gateway     │  │  • NAT Gateway   │
        │  • Bastion Host    │  │  • Bastion Host    │  │  • Bastion Host  │
        │                    │  │                    │  │                  │
        │  ┌────────────────┐│  │  ┌────────────────┐│  │  ┌────────────────┐
        │  │ NAT GW (1)     ││  │  │ NAT GW (2)     ││  │  │ NAT GW (3)     │
        │  │ EIP: x.x.x.x   ││  │  │ EIP: y.y.y.y   ││  │  │ EIP: z.z.z.z   │
        │  └────────┬───────┘│  │  └────────┬───────┘│  │  └────────┬───────┘
        │           │        │  │           │        │  │           │        │
        │  ┌────────▼─────┐  │  │  ┌────────▼─────┐  │  │  ┌────────▼─────┐  │
        │  │Private Route  │  │  │  │Private Route  │  │  │  │Private Route  │  │
        │  │Table (1)      │  │  │  │Table (2)      │  │  │  │Table (3)      │  │
        │  │0.0.0.0/0 →    │  │  │  │0.0.0.0/0 →    │  │  │  │0.0.0.0/0 →    │  │
        │  │NAT GW (1)     │  │  │  │NAT GW (2)     │  │  │  │NAT GW (3)     │  │
        │  └────────┬─────┘  │  │  └────────┬─────┘  │  │  └────────┬─────┘  │
        │           │        │  │           │        │  │           │        │
        │  ┌────────▼──────┐ │  │  ┌────────▼──────┐ │  │  ┌────────▼──────┐ │
        │  │Private Subnet │ │  │  │Private Subnet │ │  │  │Private Subnet │ │
        │  │10.0.11.0/24   │ │  │  │10.0.12.0/24   │ │  │  │10.0.13.0/24   │ │
        │  │(251 IPs)      │ │  │  │(251 IPs)      │ │  │  │(251 IPs)      │ │
        │  │                │ │  │  │                │ │  │  │                │ │
        │  │Resources:      │ │  │  │Resources:      │ │  │  │Resources:      │ │
        │  │• App Servers   │ │  │  │• App Servers   │ │  │  │• App Servers   │ │
        │  │• Databases     │ │  │  │• Databases     │ │  │  │• Databases     │ │
        │  │• Cache Nodes   │ │  │  │• Cache Nodes   │ │  │  │• Cache Nodes   │ │
        │  │• EKS Workers   │ │  │  │• EKS Workers   │ │  │  │• EKS Workers   │ │
        │  │• Lambda        │ │  │  │• Lambda        │ │  │  │• Lambda        │ │
        │  └────────────────┘ │  │  └────────────────┘ │  │  └────────────────┘ │
        │                    │  │                    │  │                  │
        └────────────────────┘  └────────────────────┘  └──────────────────┘
                  │                       │                       │
                  └───────────────────────┼───────────────────────┘
                                          │
                        ┌─────────────────▼──────────────────┐
                        │    VPC (10.0.0.0/16)               │
                        │    • 65,536 Total IP Addresses     │
                        │    • 3 Public + 3 Private Subnets  │
                        │    • Multi-AZ for HA               │
                        └──────────────────────────────────────┘
```

### Key Architecture Features

| Feature | Details |
|---------|---------|
| **Internet Gateway** | Single IGW attached to VPC; routes all public internet traffic |
| **Public Subnets** | 3 subnets across 3 AZs with auto-assign public IPs enabled |
| **NAT Gateways** | 3 NAT gateways (1 per AZ) for private subnet outbound traffic |
| **Private Subnets** | 3 subnets across 3 AZs with no internet exposure |
| **Route Tables** | 1 public + 3 private route tables with proper routing rules |
| **High Availability** | Multi-AZ deployment ensures fault tolerance |
| **Network Isolation** | Public/Private separation for security |

### Traffic Flow Architecture

```
INBOUND TRAFFIC (Internet → AWS):
══════════════════════════════════════════════════════════════════════════
   Internet → IGW → Public Subnet → Allowed by Security Groups/NACLs
   Internet → IGW → Cannot reach Private Subnets (No direct route)

OUTBOUND TRAFFIC (Private Resources → Internet):
══════════════════════════════════════════════════════════════════════════
   Private Resources → NAT GW (same AZ) → IGW → Internet
   • Each AZ is independent
   • Consistent outbound IP via Elastic IP
   • Prevents direct internet exposure of private resources

INTER-SUBNET COMMUNICATION (Same AZ):
══════════════════════════════════════════════════════════════════════════
   Public Subnet (AZ-1) ↔ Private Subnet (AZ-1) via VPC local route
   Private Subnet (AZ-1) → App Server → Database (same AZ)

INTER-AZ COMMUNICATION:
══════════════════════════════════════════════════════════════════════════
   Public Subnet (AZ-1) ↔ Public Subnet (AZ-2) via VPC local route
   Private Subnet (AZ-1) ↔ Private Subnet (AZ-2) via VPC local route
   All via 10.0.0.0/16 routing (no NAT needed for inter-AZ)
```

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

## Terraform  Strategies & Flow

### Strategy 1: Standard Terraform Workflow

This project follows the **Immutable Infrastructure** pattern where all infrastructure is defined as code and versioned.

```
┌─────────────────────────────────────────────────────────────┐
│              STANDARD TERRAFORM WORKFLOW                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. WRITE PHASE                                             │
│     └─ Define infrastructure in .tf files                  │
│     └─ Update variables in terraform.tfvars                │
│     └─ Commit to version control (git)                     │
│                                                              │
│  2. PLAN PHASE                                              │
│     └─ terraform init       (Initialize working directory) │
│     └─ terraform plan       (Preview changes)               │
│     └─ Review plan output                                  │
│                                                              │
│  3. APPLY PHASE                                             │
│     └─ terraform apply      (Create/modify resources)      │
│     └─ AWS resources created                               │
│     └─ terraform.tfstate updated                           │
│                                                              │
│  4. VERIFY PHASE                                            │
│     └─ terraform output     (Check created resources)       │
│     └─ AWS Console verification                            │
│     └─ Network connectivity tests                          │
│                                                              │
│  5. MAINTENANCE PHASE                                       │
│     └─ Backup terraform.tfstate                            │
│     └─ Push state to S3 backend (state-backend module)    │
│     └─ Enable state locking with DynamoDB                 │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Strategy 2: State Management (Local → Remote S3)

This project supports both local and remote state management:

**Phase 1: Initial Setup (Local State)**
- Terraform state stored locally in `terraform.tfstate`
- Suitable for development/testing
- Risk: State file loss if laptop crashes

**Phase 2: Production Setup (Remote S3 + DynamoDB)**
- Use `state-backend/` directory to create S3 bucket and DynamoDB table
- Migrate local state to remote S3 backend
- DynamoDB table provides state locking to prevent conflicts
- Multiple team members can safely access the same state

```
LOCAL STATE (Development)              REMOTE STATE (Production)
═════════════════════════════         ═══════════════════════════════
terraform.tfstate                      S3 Bucket
(Local file)                           │
    ↓                                  ├─ terraform.tfstate
Lost if deleted                        ├─ terraform.tfstate.backup
No locking                             └─ Version history

                                       DynamoDB Table
                                       └─ State Locks (LockID)
                                           ├─ Prevents concurrent applies
                                           ├─ Auto-unlock on timeout
                                           └─ Audit trail
```

### Strategy 3: Deployment Architecture Flow

```
COMPLETE DEPLOYMENT FLOW
════════════════════════════════════════════════════════════════════════

STEP 1: CREATE STATE BACKEND (ONE-TIME SETUP)
──────────────────────────────────────────────
  cd Terraform/VPC/VPC-NORMAL/state-backend
  terraform init
  terraform plan
  terraform apply
  ├─ Creates S3 bucket (terraform-state-backend-production-xxxxx)
  ├─ Creates DynamoDB table (terraform-state-lock-production)
  ├─ Captures output values
  └─ Stores initial state LOCALLY


STEP 2: CONFIGURE REMOTE BACKEND (MIGRATION)
──────────────────────────────────────────────
  Uncomment backend block in VPC-NORMAL/backend.tf
  ├─ bucket         = "terraform-state-backend-production-xxxxx"
  ├─ key            = "vpc/terraform.tfstate"
  ├─ region         = "us-east-1"
  ├─ dynamodb_table = "terraform-state-lock-production"
  └─ encrypt        = true

  cd Terraform/VPC/VPC-NORMAL
  terraform init -upgrade
  ├─ Detects new backend configuration
  ├─ Prompts to migrate existing state
  ├─ Uploads local state to S3
  ├─ Creates DynamoDB lock entry
  └─ Deletes local state (terraform.tfstate)


STEP 3: CREATE MAIN VPC INFRASTRUCTURE
───────────────────────────────────────
  cd Terraform/VPC/VPC-NORMAL
  terraform plan
  terraform apply
  ├─ Creates VPC (10.0.0.0/16)
  ├─ Creates 3 Public Subnets (AZ-1, AZ-2, AZ-3)
  ├─ Creates 3 Private Subnets (AZ-1, AZ-2, AZ-3)
  ├─ Creates Internet Gateway
  ├─ Creates 3 NAT Gateways (one per AZ)
  ├─ Creates 3 Elastic IPs
  ├─ Creates Route Tables (1 public + 3 private)
  ├─ Stores state in S3
  ├─ Locks state in DynamoDB
  └─ Outputs VPC/Subnet IDs for downstream modules


STEP 4: USE OUTPUTS IN OTHER MODULES
──────────────────────────────────────
  Reference outputs in other modules:
  - EKS module uses VPC ID and private subnet IDs
  - RDS module uses private subnet IDs
  - ALB module uses public subnet IDs
  - EC2 module references security groups/VPC

  Example:
  module "eks" {
    vpc_id                = module.vpc.vpc_id
    subnet_ids            = module.vpc.private_subnet_ids
    security_group_ids    = module.vpc.security_group_ids
  }
```

### Strategy 4: Network Traffic Flow

```
PRODUCTION TRAFFIC PATTERNS
════════════════════════════════════════════════════════════════════════

SCENARIO 1: INBOUND EXTERNAL TRAFFIC (Internet User → ALB → App)
────────────────────────────────────────────────────────────────
  1. User in Internet (203.0.113.5)
     ↓
  2. Request hits Public IP (ALB EIP: 52.87.123.45)
     ↓
  3. ALB in Public Subnet (10.0.1.0/24)
     ├─ Receives on port 443 (HTTPS)
     ├─ Security group allows 0.0.0.0/0:443
     └─ ✅ ALLOWED
     ↓
  4. ALB routes to App Servers in Private Subnet (10.0.11.0/24)
     ├─ Security group allows 10.0.1.0/24:8080
     └─ ✅ ALLOWED
     ↓
  5. App responds to ALB (reverse path)
     ├─ Response uses VPC local route (free)
     └─ ✅ ALLOWED
     ↓
  6. ALB sends response to Internet
     ├─ Uses IGW (not NAT)
     └─ Response returns to user


SCENARIO 2: OUTBOUND TRAFFIC (App Server → External API)
──────────────────────────────────────────────────────────
  1. App Server in Private Subnet (10.0.11.0/24)
  2. Initiates request to external API (52.200.50.1:443)
     ├─ Destination not in 10.0.0.0/16
     └─ Route lookup: 0.0.0.0/0 → NAT Gateway
     ↓
  3. Route Table (Private AZ-1)
     └─ 0.0.0.0/0 → NAT Gateway (1) in same AZ
     ↓
  4. NAT Gateway in Public Subnet (10.0.1.0/24)
     ├─ Translates source IP: 10.0.11.x → 52.87.101.20 (EIP)
     ├─ Maintains connection state
     └─ Forwards to IGW
     ↓
  5. Internet Gateway
     └─ Routes to Internet
     ↓
  6. External API responds to 52.87.101.20
     ↓
  7. NAT Gateway translates back: 52.87.101.20 → 10.0.11.x
     ↓
  8. App receives response
     └─ Source appears as NAT EIP (52.87.101.20)


SCENARIO 3: INTER-SUBNET COMMUNICATION (APP → DATABASE)
─────────────────────────────────────────────────────────
  Case A: Same Availability Zone
  ─────────────────────────────
  App Server (10.0.1.10) → Database (10.0.11.5)
  ├─ Route lookup: destination 10.0.11.0/24
  ├─ Matches VPC CIDR 10.0.0.0/16
  ├─ VPC local route (FREE)
  └─ Direct path via VPC backbone
  
  
  Case B: Different Availability Zones (Cross-AZ)
  ──────────────────────────────────────────────
  App Server AZ-1 (10.0.1.10) → Database AZ-2 (10.0.12.5)
  ├─ Route lookup: destination 10.0.12.0/24
  ├─ Matches VPC CIDR 10.0.0.0/16
  ├─ VPC local route (minimal charge for cross-AZ)
  └─ Routed via AWS backbone (single-digit ms latency)


SCENARIO 4: PRIVATE SUBNET ISOLATION (Security)
────────────────────────────────────────────────
  Attacker in Internet (1.2.3.4)
  ↓
  Attempts SSH to Private Server (10.0.11.x)
  ├─ No route from IGW to Private Subnets
  ├─ Request cannot enter private subnet directly
  └─ ❌ BLOCKED (No route exists)

  The only way to reach private servers:
  └─ Bastion Host (jump server) in Public Subnet
     ├─ Or AWS Systems Manager Session Manager
     ├─ Or VPN connection
     └─ All authenticated access methods
```

### Strategy 5: Scaling and Extension

```
HOW TO EXTEND THIS VPC
════════════════════════════════════════════════════════════════════

EXPANSION POINT 1: ADD MORE SUBNETS
──────────────────────────────────
  Current: 3 Public + 3 Private (6 subnets total)
  
  To add 3 more private subnets:
  1. Edit variables.tf:
     private_subnet_cidrs = [
       "10.0.11.0/24",  # AZ-1 Tier 1 (DB)
       "10.0.12.0/24",  # AZ-2 Tier 1 (DB)
       "10.0.13.0/24",  # AZ-3 Tier 1 (DB)
       "10.0.21.0/24",  # AZ-1 Tier 2 (Cache)  ← NEW
       "10.0.22.0/24",  # AZ-2 Tier 2 (Cache)  ← NEW
       "10.0.23.0/24",  # AZ-3 Tier 2 (Cache)  ← NEW
     ]
  2. Create 3 new private route tables (optional, for different routing)
  3. terraform plan → verify changes
  4. terraform apply


EXPANSION POINT 2: ADD SECURITY GROUPS
──────────────────────────────────────
  Each subnet tier should have its own security group:
  ├─ ALB SG (allow 443/80 from Internet)
  ├─ App SG (allow 8080 from ALB)
  ├─ Database SG (allow 5432 from App)
  ├─ Cache SG (allow 6379 from App)
  └─ Bastion SG (allow 22 from Admin IPs)


EXPANSION POINT 3: ADD VPC ENDPOINTS
────────────────────────────────────
  For S3 and DynamoDB access without NAT:
  ├─ Gateway Endpoint: S3, DynamoDB
  ├─ Interface Endpoint: RDS, EKS, SNS, SQS
  ├─ Benefit: Reduce NAT costs for internal AWS service calls
  └─ Add to vpc.tf


EXPANSION POINT 4: ADD FLOW LOGS
────────────────────────────────
  Monitor network traffic:
  ├─ VPC Flow Logs → CloudWatch Logs
  ├─ Helps troubleshooting network issues
  ├─ Tracks allowed/denied traffic
  └─ Enable with CloudWatch log group


EXPANSION POINT 5: MULTI-REGION SETUP
──────────────────────────────────────
  Create VPCs in multiple regions:
  ├─ Create new VPC in us-west-2
  ├─ Setup peering or Transit Gateway
  ├─ Enable cross-region failover
  └─ Use Route 53 for DNS failover
```

---

## What This Configuration Does

### On Deployment (terraform apply)

1. **Creates VPC** - Isolated network space (10.0.0.0/16) with DNS enabled
2. **Creates 3 Public Subnets** - For internet-facing resources (ALB, NAT GW, Bastion)
3. **Creates 3 Private Subnets** - For backend resources (Apps, Databases, EKS Workers)
4. **Creates Internet Gateway** - Enables public subnet resources to reach internet
5. **Creates 3 NAT Gateways** - Enables private subnet outbound internet access
6. **Allocates 3 Elastic IPs** - Fixed public IPs for each NAT gateway
7. **Creates Route Tables** - Defines traffic routing rules:
   - Public route table: 0.0.0.0/0 → IGW
   - Private route tables: 0.0.0.0/0 → NAT (in same AZ)
8. **Associates Subnets** - Links subnets to appropriate route tables
9. **Stores State** - Records infrastructure state in terraform.tfstate

### What You Get

✅ **High Availability**
- Distributed across 3 availability zones
- Tolerate single AZ failure
- NAT redundancy per AZ

✅ **Security**
- Public/private network segmentation
- No direct internet access to private resources
- Consistent outbound IPs for whitelisting

✅ **Connectivity**
- Public resources accessible from internet
- Private resources can reach internet via NAT
- Inter-subnet communication within VPC

✅ **Cost Efficiency**
- Minimal NAT gateway usage (3 instead of 6)
- Proper CIDR planning (251 IPs per subnet)
- Pay only for resources used

✅ **Foundation for Scaling**
- Ready for EKS, RDS, ElastiCache deployment
- Extensible subnet design
- Outputs for module composition

### What This Does NOT Do

❌ **Doesn't create databases** - Use RDS module separately
❌ **Doesn't deploy applications** - Use EC2/ECS/EKS modules
❌ **Doesn't setup monitoring** - Add CloudWatch separately
❌ **Doesn't create security groups** - Add in app-specific modules
❌ **Doesn't enable VPN** - Configure VPN/Transit Gateway separately

---

## File Structure

```
VPC-NORMAL/
├── backend.tf                          # Remote state backend configuration
├── provider.tf                         # AWS provider config
├── variables.tf                        # Input variables
├── vpc.tf                             # VPC, subnets, NAT, routes
├── outputs.tf                         # Output values
├── terraform.tfvars                   # Variable values (git ignored)
├── terraform.tfstate                  # Local state (git ignored)
├── terraform.tfstate.backup           # State backup (git ignored)
├── .terraform/                        # Terraform cache (git ignored)
├── VPC_Architecture_Diagram_Clear.drawio  # Architecture diagram
├── state-backend/                     # S3 & DynamoDB for state management
│   ├── provider.tf
│   ├── variables.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   ├── terraform.tfstate              # State backend's own state
│   └── README.md
└── README.md                          # This file
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
