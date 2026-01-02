# Create S3 bucket for Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.s3_bucket_name}-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${var.s3_bucket_name}-${var.environment}"
  }
}

# Enable versioning for state file history
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

# Block public access to S3 bucket
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Enable MFA delete protection
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "delete_old_versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# Create DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_lock" {
  name         = "${var.dynamodb_table_name}-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled = var.enable_server_side_encryption
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name = "${var.dynamodb_table_name}-${var.environment}"
  }
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}
