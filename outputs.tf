# ============================================================
# Glue Database Outputs
# ============================================================
output "glue_database_arn" {
  description = "The ARN of the Glue catalog database"
  value       = try(aws_glue_catalog_database.main[0].arn, null)
}

output "glue_database_name" {
  description = "The name of the Glue catalog database"
  value       = try(aws_glue_catalog_database.main[0].name, null)
}

output "glue_database_id" {
  description = "The ID of the Glue catalog database"
  value       = try(aws_glue_catalog_database.main[0].id, null)
}

# ============================================================
# Glue Crawlers Outputs
# ============================================================
output "glue_crawler_arns" {
  description = "Map of crawler name to ARN"
  value       = { for k, v in aws_glue_crawler.main : k => v.arn }
}

output "glue_crawler_names" {
  description = "Map of crawler key to name"
  value       = { for k, v in aws_glue_crawler.main : k => v.name }
}

# ============================================================
# Glue Jobs Outputs
# ============================================================
output "glue_job_arns" {
  description = "Map of job key to ARN"
  value       = { for k, v in aws_glue_job.main : k => v.arn }
}

output "glue_job_names" {
  description = "Map of job key to name"
  value       = { for k, v in aws_glue_job.main : k => v.name }
}

# ============================================================
# Glue Workflows Outputs
# ============================================================
output "glue_workflows" {
  description = "Map of workflow key to workflow object"
  value       = aws_glue_workflow.main
}

# ============================================================
# IAM Role Outputs
# ============================================================
output "glue_iam_role_arn" {
  description = "The ARN of the Glue IAM role"
  value       = try(aws_iam_role.glue[0].arn, null)
}

output "glue_iam_role_name" {
  description = "The name of the Glue IAM role"
  value       = try(aws_iam_role.glue[0].name, null)
}

output "glue_iam_role_id" {
  description = "The ID of the Glue IAM role"
  value       = try(aws_iam_role.glue[0].id, null)
}
# ============================================================
# Glue Security Configuration Outputs
# ============================================================
output "glue_security_configurations" {
  description = "Map of security configuration key to name"
  value       = { for k, v in aws_glue_security_configuration.main : k => v.name }
}

output "glue_connection_names" {
  description = "Map of connection key to name"
  value       = { for k, v in aws_glue_connection.main : k => v.name }
}

output "glue_secret_arns" {
  description = "Map of secret key to ARN"
  value       = { for k, v in aws_secretsmanager_secret.main : k => v.arn }
}

# ============================================================
# General Outputs
# ============================================================
output "resource_prefix" {
  description = "The resource prefix used for naming"
  value       = local.resource_prefix
}

output "aws_account_id" {
  description = "The AWS account ID where resources are created"
  value       = data.aws_caller_identity.current.account_id
}

output "module_version" {
  description = "The version of this module"
  value       = "1.0.0"
}

# ============================================================
# Conditional Creation Outputs
# ============================================================
output "iam_role_created" {
  description = "Whether IAM role was created"
  value       = local.create_iam_role
}

output "security_group_created" {
  description = "Whether security group was created"
  value       = local.create_security_group
}
