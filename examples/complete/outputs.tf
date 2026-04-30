# ============================================================
# Glue Resources Outputs
# ============================================================
output "glue_database_name" {
  description = "The name of the Glue catalog database"
  value       = module.glue_complete.glue_database_name
}

output "glue_crawler_names" {
  description = "Map of crawler key to name"
  value       = module.glue_complete.glue_crawler_names
}

output "glue_job_names" {
  description = "Map of job key to name"
  value       = module.glue_complete.glue_job_names
}

output "glue_workflows" {
  description = "Map of workflow key to workflow object"
  value       = module.glue_complete.glue_workflows
}

output "glue_connection_names" {
  description = "Map of connection key to name"
  value       = module.glue_complete.glue_connection_names
}

output "glue_security_configurations" {
  description = "Map of security configuration key to name"
  value       = module.glue_complete.glue_security_configurations
}

output "glue_iam_role_arn" {
  description = "The ARN of the Glue IAM role"
  value       = module.glue_complete.glue_iam_role_arn
}

# ============================================================
# S3 Buckets Outputs
# ============================================================
output "s3_data_bucket" {
  description = "The S3 bucket for Glue data"
  value       = module.s3_data.bucket_id
}

output "s3_scripts_bucket" {
  description = "The S3 bucket for Glue scripts"
  value       = module.s3_scripts.bucket_id
}

output "s3_logs_bucket" {
  description = "The S3 bucket for Glue logs"
  value       = module.s3_logs.bucket_id
}

# ============================================================
# RDS Outputs
# ============================================================
output "rds_database_name" {
  description = "The RDS database name"
  value       = var.rds_database
}

# ============================================================
# Redshift Outputs
# ============================================================
output "redshift_database_name" {
  description = "The Redshift database name"
  value       = var.redshift_database
}

# ============================================================
# Security Outputs
# ============================================================
output "glue_security_group_id" {
  description = "The ID of the Glue security group"
  value       = module.glue_complete.glue_security_group_id
}

# ============================================================
# Secrets Outputs
# ============================================================
output "glue_secret_arns" {
  description = "Map of Glue secret key to ARN"
  value       = module.glue_complete.glue_secret_arns
}
