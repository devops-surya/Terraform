# Backend configuration to store Terraform state in S3 with DynamoDB state locking
# Configure this after creating the S3 bucket and DynamoDB table using the state-backend module
#
# After running terraform apply in the state-backend directory:
# 1. Uncomment this configuration
# 2. Replace the S3 bucket name and DynamoDB table name with your actual values
# 3. Run: terraform init -upgrade

terraform {
  # Uncomment and configure after state-backend resources are created
  
   backend "s3" {
     bucket         = "terraform-state-backend-vpcmodule-production-440744235311"
     key            = "vpc-module/terraform.tfstate"
     region         = "us-east-1"
     dynamodb_table = "terraform-state-lock-vpcmodule-production"
     encrypt        = true
   }
}

# Migration steps:
# 1. First, create the S3 bucket and DynamoDB table by applying the state-backend module
# 2. Uncomment the backend block above
# 3. Update the bucket name and dynamodb_table values with actual resource names
# 4. Run: terraform init -upgrade
# 5. Choose 'yes' when asked to migrate the existing state
