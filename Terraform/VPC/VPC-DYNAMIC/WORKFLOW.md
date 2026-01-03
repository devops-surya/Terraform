# 🔄 Manual Workflow Diagram

## Terraform Workspace Deployment Workflow

```
┌─────────────────────────────────────────────────────────────┐
│  Manual Terraform Commands                                  │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │  STEP 1: Backend Init         │
        │  ─────────────────────        │
        │  $ terraform init             │
        │  • Configure S3 backend       │
        │  • Download providers         │
        │  ✓ Backend ready              │
        └───────────┬───────────────────┘
                    │
                    ▼
        ┌───────────────────────────────┐
        │  STEP 2: Workspace Setup      │
        │  ─────────────────────        │
        │  $ terraform workspace new dev│
        │  or                           │
        │  $ terraform workspace select │
        │  ✓ Workspace: dev             │
        └───────────┬───────────────────┘
                    │
                    ▼
        ┌───────────────────────────────┐
        │  STEP 3: Plan Changes         │
        │  ─────────────────────        │
        │  $ terraform plan \           │
        │    -var-file=environments/    │
        │    dev.tfvars                 │
        │  ✓ Review plan output         │
        └───────────┬───────────────────┘
                    │
                    ▼
        ┌───────────────────────────────┐
        │  STEP 4: Apply Changes        │
        │  ─────────────────────        │
        │  $ terraform apply \          │
        │    -var-file=environments/    │
        │    dev.tfvars                 │
        │  • State: env/dev/...tfstate  │
        │  ✓ Infrastructure deployed    │
        └───────────────────────────────┘
```

## S3 State Organization

```
S3 Bucket: terraform-state-backend-vpc-dynamic-production-440744235311
│
├── env/
│   ├── dev/
│   │   └── vpc-dynamic/
│   │       └── terraform.tfstate  ← Dev workspace state
│   │
│   ├── staging/
│   │   └── vpc-dynamic/
│   │       └── terraform.tfstate  ← Staging workspace state
│   │
│   └── prod/
│       └── vpc-dynamic/
│           └── terraform.tfstate  ← Prod workspace state
│
└── DynamoDB Table: terraform-state-lock-vpc-dynamic-production
    ├── LockID: env/dev/vpc-dynamic/terraform.tfstate-md5
    ├── LockID: env/staging/vpc-dynamic/terraform.tfstate-md5
    └── LockID: env/prod/vpc-dynamic/terraform.tfstate-md5
```

## Workspace State Isolation

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   DEV       │     │  STAGING    │     │   PROD      │
│ Workspace   │     │  Workspace  │     │  Workspace  │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                   │                    │
       │ Uses:             │ Uses:              │ Uses:
       │ dev.tfvars        │ staging.tfvars     │ prod.tfvars
       │                   │                    │
       ▼                   ▼                    ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ VPC CIDR    │     │ VPC CIDR    │     │ VPC CIDR    │
│ 10.10.0.0/16│     │ 10.20.0.0/16│     │ 10.0.0.0/16 │
├─────────────┤     ├─────────────┤     ├─────────────┤
│ Single NAT  │     │ Multi NAT   │     │ Multi NAT   │
├─────────────┤     ├─────────────┤     ├─────────────┤
│ State:      │     │ State:      │     │ State:      │
│ env/dev/    │     │ env/staging/│     │ env/prod/   │
└─────────────┘     └─────────────┘     └─────────────┘
```

## Deployment Process Flow

### Plan Phase
```
User runs manual commands:
  $ terraform workspace select dev
  $ terraform plan -var-file="environments/dev.tfvars"
                          │
                          ▼
              ┌───────────────────┐
              │ Switch Workspace  │
              │ to: dev           │
              └─────────┬─────────┘
                        │
                        ▼
              ┌───────────────────┐
              │ Load dev.tfvars   │
              │ manually          │
              └─────────┬─────────┘
                        │
                        ▼
              ┌───────────────────┐
              │ terraform plan    │
              │ shows changes     │
              └───────────────────┘
```

### Apply Phase
```
User runs manual commands:
  $ terraform workspace select dev
  $ terraform apply -var-file="environments/dev.tfvars"
                          │
                          ▼
              ┌───────────────────┐
              │ Confirm workspace │
              │ is correct        │
              └─────────┬─────────┘
                        │
                        ▼
              ┌───────────────────┐
              │ Load dev.tfvars   │
              │ manually          │
              └─────────┬─────────┘
                        │
                        ▼
            ┌──────────────────┐
            │ User Confirmation│
            │ Type "yes"       │
            └────────┬─────────┘
                     │
                     ▼
            ┌──────────────────┐
            │ Apply Changes    │
            │ State → S3       │
            │ env/dev/         │
            └──────────────────┘
```

## Environment Promotion Flow

```
┌──────────────────────────────────────────────────────────┐
│                   Development                            │
│  .\scripts\deploy.ps1 -Environment dev -Action apply     │
│  • Test and validate                                     │
│  • State: env/dev/                                       │
└────────────────────┬─────────────────────────────────────┘
                     │
                     │ Code validated ✓
   $ terraform workspace select dev                        │
│  $ terraform apply -var-file="environments/dev.tfvars"   │
│  • Test and validate                                     │
│  • State: env/dev/                                       │
└────────────────────┬─────────────────────────────────────┘
                     │
                     │ Code validated ✓
                     ▼
┌──────────────────────────────────────────────────────────┐
│                   Staging                                │
│  $ terraform workspace select staging                    │
│  $ terraform apply -var-file="environments/staging.tfva" │
│  • Pre-production testing                                │
│  • State: env/staging/                                   │
└────────────────────┬─────────────────────────────────────┘
                     │
                     │ Testing passed ✓
                     ▼
┌──────────────────────────────────────────────────────────┐
│                   Production                             │
│  $ terraform workspace select prod                       │
│  $ terraform plan -var-file="environments/prod.tfvars"   │
│  $ terraform apply -var-file="environments/prod.tfvars"  │
│  • Production deployment                                 │
│  • State: env/prod/                                      │
│  • Manual review required
┌──Manual Terraform Commands Reference

```
┌─────────────────────────────────────────────────────────────┐
│ Command                          │ Purpose                  │
├─────────────────────────────────────────────────────────────┤
│ terraform init                   │ Initialize backend       │
│ terraform workspace list         │ List all workspaces      │
│ terraform workspace new <name>   │ Create workspace         │
│ terraform workspace select <name>│ Switch workspace         │
│ terraform workspace show         │ Show current workspace   │
│ terraform plan -var-file=...     │ Plan infrastructure      │
│ terraform apply -var-file=...    │ Apply changes            │
│ terraform destroy -var-file=...  │ Destroy infrastructure   │
│ terraform output                 │ View outputs             │
│ terManual Control**
   - Full control over terraform commands
   - Explicit workspace management
   - Clear understanding of each step

2. **State Isolation (Automatic)**
   - Each workspace has separate S3 folder via `workspace_key_prefix`
   - No risk of applying dev changes to prod
   - Clear state organization in S3

3. **Safety Features**
   - Manual workspace selection prevents accidents
   - Must specify correct .tfvars file each time
   - Review plan before apply

4. **Important Reminders**
   - Always switch workspace BEFORE running terraform commands
   - Always specify correct -var-file for the environment
   - Workspace name ≠ automatic variable loading
   - Double-check workspace with: `terraform workspace show`

---

**Remember**: Workspace controls WHERE state is stored in S3. Variables file controls WHAT gets deployed. Both must be specified correctly
   - Reusable scripts

---

**Remember**: All scripts are fully automated. Just run them with the environment name, and they handle the rest!
