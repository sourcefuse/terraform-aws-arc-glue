variable "region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "namespace" {
  description = "Namespace/organization identifier"
  type        = string
  default     = "arc"
}

variable "environment" {
  description = "Environment identifier"
  type        = string
  default     = "poc"

  validation {
    condition     = can(regex("^(dev|staging|prod|poc)$", var.environment))
    error_message = "Environment must be dev, staging, prod, or poc."
  }
}

variable "name" {
  description = "Name prefix for resources"
  type        = string
  default     = "glue-complete"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Project     = "Glue Complete Example"
    Environment = "POC"
    ManagedBy   = "Terraform"
  }
}

# RDS Configuration
variable "rds_database" {
  description = "RDS database name"
  type        = string
  default     = "testdb"
}

variable "rds_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
  default     = "ChangeMe123!" # Change this for production
}

# Redshift Configuration
variable "redshift_username" {
  description = "Redshift username"
  type        = string
  default     = "admin"
}

variable "redshift_password" {
  description = "Redshift master password"
  type        = string
  sensitive   = true
}

variable "redshift_database" {
  description = "Redshift database name"
  type        = string
  default     = "dev"
}

variable "authorized_accounts" {
  description = "List of AWS account ARNs for cross-account Glue catalog access"
  type        = list(string)
  default     = []
}

variable "organization_id" {
  description = "AWS Organization ID for catalog resource policy condition"
  type        = string
  default     = ""
}

variable "permissions_boundary_arn" {
  description = "ARN of IAM permissions boundary to attach to the Glue role"
  type        = string
  default     = null
}
