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
  region = var.region

  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Example   = "Complete Glue Setup"
    }
  }
}

data "aws_caller_identity" "current" {}

# ============================================================
# VPC / Network Data Sources
# ============================================================
data "aws_vpc" "arc_poc_vpc" {
  filter {
    name   = "tag:Name"
    values = ["arc-poc-vpc"]
  }
}

data "aws_subnets" "private_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.arc_poc_vpc.id]
  }
  filter {
    name   = "tag:Type"
    values = ["private"]
  }
}

# ============================================================
# S3 Buckets (data, scripts, logs) via sourcefuse arc-s3
# ============================================================
module "s3_data" {
  source  = "sourcefuse/arc-s3/aws"
  version = "0.0.7"

  name          = "${var.namespace}-${var.environment}-glue-data"
  force_destroy = true

  enable_versioning = true
  server_side_encryption_config_data = {
    bucket_key_enabled = true
    sse_algorithm      = "AES256"
  }

  tags = merge(var.tags, { Purpose = "Glue Data" })
}

module "s3_scripts" {
  source  = "sourcefuse/arc-s3/aws"
  version = "0.0.7"

  name          = "${var.namespace}-${var.environment}-glue-scripts"
  force_destroy = true

  enable_versioning = true
  server_side_encryption_config_data = {
    bucket_key_enabled = true
    sse_algorithm      = "AES256"
  }

  tags = merge(var.tags, { Purpose = "Glue Scripts" })
}

module "s3_logs" {
  source  = "sourcefuse/arc-s3/aws"
  version = "0.0.7"

  name          = "${var.namespace}-${var.environment}-glue-logs"
  force_destroy = true

  enable_versioning = false
  server_side_encryption_config_data = {
    bucket_key_enabled = true
    sse_algorithm      = "AES256"
  }

  tags = merge(var.tags, { Purpose = "Glue Logs" })
}

# ============================================================
# RDS Module
# ============================================================
module "rds" {
  source  = "sourcefuse/arc-db/aws"
  version = "4.0.2"

  namespace   = var.namespace
  environment = var.environment
  name        = "glue-rds"

  engine_type    = "rds"
  engine         = "postgres"
  engine_version = "14.22"
  license_model  = "postgresql-license"

  username             = "glueadmin"
  manage_user_password = true
  database_name        = var.rds_database
  port                 = 5432

  storage_encrypted = true

  performance_insights_enabled = true

  db_subnet_group_data = {
    name       = "${var.namespace}-${var.environment}-glue-rds-subnet-group"
    create     = true
    subnet_ids = data.aws_subnets.private_subnets.ids
  }

  vpc_id = data.aws_vpc.arc_poc_vpc.id

  backup_retention_period      = 7
  preferred_maintenance_window = "Mon:03:00-Mon:04:00"
  preferred_backup_window      = "04:00-05:00"

  tags = merge(var.tags, { Component = "RDS for Glue" })
}

# ============================================================
# Redshift Module
# ============================================================
module "redshift" {
  source  = "sourcefuse/arc-redshift/aws"
  version = "0.0.1"

  namespace   = var.namespace
  environment = var.environment
  name        = "${var.name}-redshift"

  database_name          = var.redshift_database
  master_username        = var.redshift_username
  create_random_password = true

  node_type    = "ra3.xlplus"
  cluster_type = "single-node"

  subnet_ids = data.aws_subnets.private_subnets.ids
  vpc_id     = data.aws_vpc.arc_poc_vpc.id

  encrypted           = true
  skip_final_snapshot = true

  security_group_data = {
    create = true
    ingress_rules = [{
      description = "Redshift from VPC"
      cidr_block  = data.aws_vpc.arc_poc_vpc.cidr_block
      from_port   = 5439
      ip_protocol = "tcp"
      to_port     = "5439"
    }]
    egress_rules = [{
      description = "All outbound"
      cidr_block  = "0.0.0.0/0"
      from_port   = -1
      ip_protocol = "-1"
      to_port     = "-1"
    }]
  }

  tags = merge(var.tags, { Component = "Redshift for Glue" })
}

# ============================================================
# Complete Glue Module
# ============================================================
module "glue_complete" {
  source = "../../"

  namespace   = var.namespace
  environment = var.environment
  name        = var.name
  region      = var.region
  tags        = var.tags

  iam_config = {
    create_role      = true
    role_description = "Complete Glue IAM role"
    role_policies = {
      "AmazonAthenaFullAccess" = "arn:aws:iam::aws:policy/AmazonAthenaFullAccess"
    }
    permissions_boundary = var.permissions_boundary_arn
  }

  # Secrets — root module creates Secrets Manager entries
  secrets_config = {
    secrets = {
      "rds-password" = {
        name          = "${var.namespace}-${var.environment}-rds-password"
        description   = "RDS master password"
        secret_string = jsonencode({ password = var.rds_password })
      }
    }
  }

  glue_config = {
    create = true

    database = {
      create      = true
      name        = "${var.namespace}_${var.environment}_db"
      description = "Complete Glue database with all features"
    }

    workflows = {
      "data-pipeline" = {
        description         = "Complete data processing workflow"
        max_concurrent_runs = 5
      }
    }

    triggers = {
      "daily-trigger" = {
        type          = "SCHEDULED"
        description   = "Daily trigger for data pipeline"
        schedule      = "cron(0 1 * * ? *)"
        workflow_name = "${var.namespace}-${var.environment}-${var.name}-data-pipeline"
        actions       = [{ job_name = "${var.namespace}-${var.environment}-${var.name}-spark-etl" }]
      }

      "conditional-trigger" = {
        type        = "CONDITIONAL"
        description = "Conditional trigger based on crawler success"
        predicate = {
          logical = "AND"
          conditions = [{
            crawler_name = "${var.namespace}-${var.environment}-${var.name}-s3-structured"
            state        = "SUCCEEDED"
            crawl_state  = "SUCCEEDED"
          }]
        }
        actions = [{ job_name = "${var.namespace}-${var.environment}-${var.name}-python-shell" }]
      }
    }

    classifiers = {
      "json-classifier" = {
        json_classifier = { name = "json-classifier", json_path = "$[*]" }
      }
      "custom-csv" = {
        csv_classifier = {
          name            = "custom-csv"
          delimiter       = "|"
          quote_char      = "\""
          contains_header = "PRESENT"
          header          = ["id", "name", "timestamp", "value"]
        }
      }
      "grok-logs" = {
        grok_classifier = {
          name           = "grok-logs"
          classification = "logs"
          grok_pattern   = "%%{TIMESTAMP_ISO8601:timestamp} %%{LOGLEVEL:level} %%{GREEDYDATA:message}"
        }
      }
    }

    security_configurations = {
      "encryption-config" = {
        encryption_configuration = {
          s3_encryption            = { s3_encryption_mode = "SSE-S3" }
          cloudwatch_encryption    = { cloudwatch_encryption_mode = "DISABLED" }
          job_bookmarks_encryption = { job_bookmarks_encryption_mode = "DISABLED" }
        }
      }
    }

    catalog_encryption_settings = {
      create                         = true
      connection_password_encryption = true
      at_rest_encryption             = { catalog_encryption_mode = "SSE-KMS" }
      s3_encryption                  = { s3_encryption_mode = "SSE-KMS" }
    }

    catalog_resource_policy = {
      create      = true
      description = "Cross-account access policy"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect    = "Allow"
          Principal = { AWS = var.authorized_accounts }
          Action    = ["glue:GetDatabase", "glue:GetDatabases", "glue:GetTable", "glue:GetTables"]
          Resource  = "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:catalog"
          Condition = { StringEquals = { "aws:PrincipalOrgID" = var.organization_id } }
        }]
      })
    }
  }

  glue_crawlers = {
    "s3-structured" = {
      database_name = "${var.namespace}_${var.environment}_db"
      description   = "Crawler for structured S3 data"
      schedule      = "cron(0 2 * * ? *)"
      table_prefix  = "structured_"

      schema_change_policy  = { delete_behavior = "LOG", update_behavior = "UPDATE_IN_DATABASE" }
      recrawl_policy        = { recrawl_behavior = "CRAWL_NEW_FOLDERS_ONLY" }
      lineage_configuration = { crawler_lineage_settings = "ENABLE" }

      targets = {
        s3_targets = [{
          path        = "s3://${module.s3_data.bucket_id}/"
          exclusions  = ["**/*.tmp", "**/.git/**"]
          sample_size = 100
        }]
      }
    }

    "s3-json" = {
      database_name = "${var.namespace}_${var.environment}_db"
      description   = "Crawler for JSON data"
      table_prefix  = "json_"
      classifiers   = ["${var.namespace}-${var.environment}-${var.name}-json-classifier"]

      targets = {
        s3_targets = [{ path = "s3://${module.s3_data.bucket_id}/" }]
      }
    }

    "jdbc-rds" = {
      database_name = "${var.namespace}_${var.environment}_db"
      description   = "Crawler for RDS database"
      schedule      = "cron(0 3 * * ? *)"

      targets = {
        jdbc_targets = [{
          connection_name = "${var.namespace}-${var.environment}-${var.name}-rds-connection"
          path            = "${var.rds_database}/%"
          exclusions      = ["temp_%"]
        }]
      }
    }

    "jdbc-redshift" = {
      database_name = "${var.namespace}_${var.environment}_db"
      description   = "Crawler for Redshift"
      schedule      = "cron(0 4 * * ? *)"

      targets = {
        jdbc_targets = [{
          connection_name = "${var.namespace}-${var.environment}-${var.name}-redshift-connection"
          path            = "${var.redshift_database}/%"
        }]
      }
    }
  }

  glue_jobs = {
    "spark-etl" = {
      description = "Spark ETL job for data transformation"
      command = {
        name            = "glueetl"
        script_location = "s3://${module.s3_scripts.bucket_id}/etl/spark-transform.py"
        python_version  = "3"
      }
      default_arguments = {
        "--job-language"                     = "python"
        "--TempDir"                          = "s3://${module.s3_data.bucket_id}/temp/"
        "--enable-metrics"                   = "true"
        "--enable-continuous-cloudwatch-log" = "true"
        "--job-bookmark-option"              = "job-bookmark-enable"
      }
      max_retries  = 2
      timeout      = 60
      max_capacity = 10.0
      glue_version = "4.0"
    }

    "python-shell" = {
      description = "Python Shell job for light processing"
      command = {
        name            = "pythonshell"
        script_location = "s3://${module.s3_scripts.bucket_id}/shell/validate.py"
        python_version  = "3.9"
      }
      default_arguments = { "--job-language" = "python" }
      max_capacity      = 0.0625
      max_retries       = 1
      glue_version      = "1.0"
    }

    "ray-job" = {
      description = "Ray job for distributed computing"
      command = {
        name            = "glueray"
        script_location = "s3://${module.s3_scripts.bucket_id}/ray/distributed.py"
        runtime         = "Ray2.4"
        python_version  = "3.9"
      }
      number_of_workers = 2
      worker_type       = "Z.2X"
      glue_version      = "4.0"
      default_arguments = { "--ray-job-num-workers" = "2" }
    }
  }

  glue_connections = {
    "rds-connection" = {
      connection_type = "JDBC"
      description     = "Connection to RDS PostgreSQL"
      connection_properties = {
        JDBC_CONNECTION_URL = "jdbc:postgresql://${module.rds.endpoint}:5432/${var.rds_database}"
        USERNAME            = "glueadmin"
        PASSWORD            = var.rds_password
      }
      physical_connection_requirements = {
        subnet_id              = data.aws_subnets.private_subnets.ids[0]
        security_group_id_list = []
      }
    }

    "redshift-connection" = {
      connection_type = "JDBC"
      description     = "Connection to Redshift"
      connection_properties = {
        JDBC_CONNECTION_URL = "jdbc:redshift://${module.redshift.cluster_endpoint}:5439/${var.redshift_database}"
        USERNAME            = var.redshift_username
        PASSWORD            = var.redshift_password
      }
      physical_connection_requirements = {
        subnet_id              = data.aws_subnets.private_subnets.ids[0]
        security_group_id_list = [module.redshift.cluster_security_group_id]
      }
    }
  }


  vpc_config = {
    create_security_group      = true
    vpc_id                     = data.aws_vpc.arc_poc_vpc.id
    security_group_description = "Security group for Glue connections"
    ingress_rules = {
      "https-access" = { description = "HTTPS access", from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["10.0.0.0/8"] }
    }
    egress_rules = {
      "all-outbound" = { description = "All outbound traffic", from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] }
    }
    subnet_ids = data.aws_subnets.private_subnets.ids
  }
}
