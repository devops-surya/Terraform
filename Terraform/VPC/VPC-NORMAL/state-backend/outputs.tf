output "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_lock.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_lock.arn
}

output "backend_config_snippet" {
  description = "Backend configuration snippet to use in other Terraform configurations"
  value       = <<-EOT
    backend "s3" {
      bucket         = "${aws_s3_bucket.terraform_state.id}"
      key            = "vpc/terraform.tfstate"
      region         = "${data.aws_caller_identity.current.account_id}"
      dynamodb_table = "${aws_dynamodb_table.terraform_lock.name}"
      encrypt        = true
    }
  EOT
}
