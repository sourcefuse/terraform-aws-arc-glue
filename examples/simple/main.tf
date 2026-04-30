terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 7.0.0"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = "arc-poc-2"
}

# ============================================================
# S3 Bucket for Data Storage
# ============================================================
module "s3_bucket" {
  source  = "sourcefuse/arc-s3/aws"
  version = "0.0.7"

  name = "${var.namespace}-${var.environment}-glue-data"

  # Enable versioning
  enable_versioning = true

  # Server-side encryption
  server_side_encryption_config_data = {
    bucket_key_enabled = true
    sse_algorithm      = "AES256"
  }

  # Tags
  tags = merge(var.tags, {
    Purpose = "Glue Data Storage"
  })
}

# ============================================================
# Simple Glue Example
# ============================================================
module "glue" {
  source = "../../"

  namespace   = var.namespace
  environment = var.environment
  name        = var.name
  region      = var.region

  tags = var.tags

  # Simple Glue setup
  glue_config = {
    create = true

    # Create a database
    database = {
      create      = true
      name        = "my_database"
      description = "Simple Glue database"
    }

    # Create a simple S3 crawler
    crawlers = {
      "s3_crawler" = {
        database_name = "my_database"
        description   = "S3 data crawler"

        targets = {
          s3_targets = [{
            path = "s3://${var.namespace}-${var.environment}-glue-data/"
          }]
        }
      }
    }
  }

  # Simple IAM setup
  iam_config = {
    create_role      = true
    role_name        = null
    role_description = "Simple Glue IAM role"
  }
}
