# ============================================================
# S3 Bucket Outputs
# ============================================================
output "s3_bucket_id" {
  description = "S3 bucket ID for data storage"
  value       = module.s3_bucket.bucket_id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = module.s3_bucket.bucket_arn
}

# ============================================================
# Glue Outputs
# ============================================================
output "database_name" {
  description = "Glue database name"
  value       = module.glue.glue_database_name
}

output "crawler_names" {
  description = "Glue crawler names"
  value       = module.glue.glue_crawler_names
}

output "iam_role_arn" {
  description = "IAM role ARN"
  value       = module.glue.glue_iam_role_arn
}

output "resource_prefix" {
  description = "Resource prefix used"
  value       = module.glue.resource_prefix
}
