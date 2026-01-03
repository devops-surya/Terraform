# Terraform State Backend Setup for VPC-DYNAMIC

This directory contains the Terraform configuration to create AWS resources for managing Terraform state files for the VPC-DYNAMIC project with workspace support:
- **S3 Bucket**: Stores the Terraform state files with versioning and encryption
- **DynamoDB Table**: Provides state locking to prevent concurrent modifications

## Features

### S3 Bucket
- ✅ Versioning enabled for state file history
- ✅ Server-side encryption (AES-256)
- ✅ Public access blocked
- ✅ Lifecycle policies to manage old versions
- ✅ Globally unique bucket name with account ID and vpc-dynamic identifier
- ✅ Workspace-aware state storage (env/dev, env/staging, env/prod)

### DynamoDB Table
- ✅ Point-in-time recovery enabled
- ✅ Server-side encryption enabled
- ✅ State locking support (LockID as primary key)
- ✅ On-demand billing mode

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- Appropriate AWS IAM permissions to create S3 buckets and DynamoDB tables

## Deployment

### Step 1: Create state-backend resources

```bash
cd state-backend
terraform init
terraform plan
terraform apply
```

This will output:
- S3 bucket name
- DynamoDB table name
- Backend configuration snippet

### Step 2: Configure VPC module to use the backend

After the state-backend is created, update the `backend.tf` file in parent directory (`vpcmodule-usage`) with the output values:

```hcl
terraform {
  backend "s3" {
    bucket         = "<S3_BUCKET_NAME_FROM_OUTPUT>"
    key            = "vpc-module/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "<DYNAMODB_TABLE_NAME_FROM_OUTPUT>"
    encrypt        = true
  }
}
```

Then initialize the backend:

```bash
cd ..
terraform init -upgrade
# Choose 'yes' when prompted to migrate existing state
```

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region | `us-east-1` |
| `project_name` | Project name for tagging | `my-project` |
| `environment` | Environment name | `production` |
| `s3_bucket_name` | S3 bucket prefix | `terraform-state-backend` |
| `dynamodb_table_name` | DynamoDB table prefix | `terraform-state-lock` |
| `enable_versioning` | Enable S3 versioning | `true` |
| `enable_server_side_encryption` | Enable S3 encryption | `true` |

## Outputs

- `s3_bucket_name`: The created S3 bucket name
- `s3_bucket_arn`: ARN of the S3 bucket
- `dynamodb_table_name`: The created DynamoDB table name
- `dynamodb_table_arn`: ARN of the DynamoDB table
- `backend_config_snippet`: Ready-to-use backend configuration

## Cost Estimation

- **S3 Bucket**: Minimal cost (storage + requests)
- **DynamoDB**: On-demand pricing (very cost-effective for low usage)

## Security Considerations

- All data is encrypted at rest
- Public access is completely blocked
- State locking prevents race conditions
- Versioning allows recovery of previous states
- AWS Tagging for easy resource tracking

## Destroying Resources

⚠️ **WARNING**: Destroying these resources will prevent access to your Terraform state.

Before destroying, ensure you have backups or have migrated your state.

```bash
terraform destroy
```

## Troubleshooting

### Error: "BucketAlreadyExists"
The S3 bucket name is globally unique. Ensure you customize the `s3_bucket_name` variable with a unique prefix.

### Error: "AccessDenied" when running terraform apply
Ensure your AWS credentials have permissions to:
- `s3:CreateBucket`
- `s3:PutBucketVersioning`
- `s3:PutBucketPublicAccessBlock`
- `dynamodb:CreateTable`
- `dynamodb:DescribeTable`

## References

- [Terraform S3 Backend Documentation](https://www.terraform.io/language/settings/backends/s3)
- [AWS S3 Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/BestPractices.html)
- [AWS DynamoDB Documentation](https://docs.aws.amazon.com/dynamodb/)
