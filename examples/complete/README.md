# Complete Glue Example

This example demonstrates a comprehensive, enterprise-grade AWS Glue deployment showcasing the full capabilities of the Terraform AWS ARC Glue module. It implements a production-ready data lake infrastructure with advanced ETL pipelines, multi-source integration, and enterprise security features.

## Overview

This example deploys a complete AWS Glue infrastructure including:
- **Multiple Data Sources**: S3, RDS PostgreSQL, Amazon Redshift
- **Advanced ETL Jobs**: Spark, Python Shell, and Ray jobs
- **Workflow Orchestration**: Complex multi-step data pipelines
- **Advanced Crawlers**: S3, JDBC, and Delta Lake crawlers
- **Enterprise Security**: KMS encryption, VPC integration, secrets management
- **External Connections**: JDBC connections to RDS and Redshift
- **Comprehensive Monitoring**: CloudWatch metrics, logs, and alarms
- **Cross-Account Access**: Resource policies for multi-account deployments

## Prerequisites

Before running this example, ensure you have:

- **AWS Account**: With appropriate permissions and quotas
- **VPC Infrastructure**: Existing VPC with public/private subnets
- **S3 Buckets**: Multiple buckets for data storage and scripts
- **RDS Instance**: PostgreSQL instance (or modify for other databases)
- **Redshift Cluster**: Amazon Redshift data warehouse (optional)
- **Terraform**: Version 1.5 or higher installed
- **AWS CLI**: Configured with valid credentials
- **KMS Key**: Existing KMS key for encryption (optional)
- **Advanced Knowledge**: Understanding of AWS Glue, networking, and security

## Quick Start

### 1. Clone and Navigate
```bash
git clone https://github.com/sourcefuse/terraform-aws-arc-glue.git
cd terraform-aws-arc-glue/example/complete
```

### 2. Configure Variables
Edit `terraform.tfvars` with your specific values:

```hcl
region      = "us-east-1"
namespace   = "mycompany"
environment = "prod"
name        = "enterprise-glue"

# Database Configuration
rds_password = "YourSecurePassword123!"
rds_database = "production_db"

# Redshift Configuration
redshift_username = "admin"
redshift_password = "YourSecurePassword123!"
redshift_database = "datawarehouse"

# Security Configuration
authorized_accounts = ["123456789012"]  # For cross-account access
organization_id     = "o-xxxxxxxxxx"    # For organization-wide access

tags = {
  Project     = "Enterprise Data Lake"
  Environment = "Production"
  CostCenter  = "Analytics"
  Compliance  = "HIPAA"
  ManagedBy   = "Terraform"
}
```

### 3. Review Network Configuration
Ensure your VPC configuration in `main.tf` matches your infrastructure:
```hcl
vpc_id     = "vpc-12345678"  # Your VPC ID
subnet_ids = ["subnet-12345", "subnet-67890"]  # Your private subnets
```

### 4. Initialize and Deploy
```bash
# Initialize Terraform
terraform init

# Review the comprehensive plan
terraform plan -out=tfplan

# Deploy the infrastructure
terraform apply tfplan
```

## Configuration Details

### 1. IAM Configuration
Comprehensive IAM setup with managed and custom policies:

```hcl
iam_config = {
  create_role = true
  role_name   = "${var.namespace}-${var.environment}-glue-execution-role"
  role_description = "Enterprise Glue execution role with comprehensive permissions"

  # AWS managed policies
  role_policies = {
    "AmazonS3FullAccess"           = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    "AmazonAthenaFullAccess"       = "arn:aws:iam::aws:policy/AmazonAthenaFullAccess"
    "AmazonRedshiftAllCommandsAccess" = "arn:aws:iam::aws:policy/AmazonRedshiftAllCommandsAccess"
  }

  # Cross-account access
  trusted_role_arns = var.authorized_accounts

  # Permissions boundary for security
  permissions_boundary = var.permissions_boundary_arn
}
```

### 2. Glue Security Configuration
Enterprise-grade encryption and security:

```hcl
glue_config = {
  security_configuration = {
    create = true
    name   = "${var.namespace}-${var.environment}-security-config"

    # S3 encryption
    s3_encryption = {
      s3_encryption_mode = "SSE-KMS"
      kms_key_arn        = var.kms_key_arn
    }

    # CloudWatch encryption
    cloudwatch_encryption = {
      cloudwatch_encryption_mode = "SSE-KMS"
      kms_key_arn               = var.kms_key_arn
    }

    # Job bookmark encryption
    job_bookmarks_encryption = {
      job_bookmarks_encryption_mode = "CSE-KMS"
      kms_key_arn                   = var.kms_key_arn
    }
  }
}
```

### 3. Advanced Crawlers
Multi-source data discovery with scheduling:

```hcl
glue_crawlers = {
  # S3 Raw Data Crawler
  "s3-raw-data" = {
    database_name = "${var.namespace}_${var.environment}_db"
    role_arn      = aws_iam_role.glue.arn
    targets = {
      s3_targets = [{
        path = "s3://${var.raw_data_bucket}/raw/"
      }]
    }
    schedule = "cron(0 1 * * ? *)"  # Daily at 1 AM
  }

  # RDS JDBC Crawler
  "rds-source" = {
    database_name = "${var.namespace}_${var.environment}_db"
    role_arn      = aws_iam_role.glue.arn
    targets = {
      jdbc_targets = [{
        connection_name = "rds-connection"
        path            = "${var.rds_database}/%"
      }]
    }
    schedule = "cron(0 2 * * ? *)"  # Daily at 2 AM
  }

  # Redshift JDBC Crawler
  "redshift-warehouse" = {
    database_name = "${var.namespace}_${var.environment}_db"
    role_arn      = aws_iam_role.glue.arn
    targets = {
      jdbc_targets = [{
        connection_name = "redshift-connection"
        path            = "${var.redshift_database}/%"
      }]
    }
    schedule = "cron(0 3 * * ? *)"  # Daily at 3 AM
  }

  # Delta Lake Crawler
  "delta-lake" = {
    database_name = "${var.namespace}_${var.environment}_db"
    role_arn      = aws_iam_role.glue.arn
    targets = {
      delta_data_targets = [{
        delta_tables = [{
          name        = "customer_data"
          database_name = "delta_lake_db"
        }]
        write_manifest = true
      }]
    }
  }
}
```

### 4. ETL Jobs
Multiple job types for different processing needs:

```hcl
glue_jobs = {
  # Spark ETL Job
  "spark-transform" = {
    role_arn     = aws_iam_role.glue.arn
    glue_version = "4.0"
    command = {
      name   = "glueetl"
      script = "s3://${var.scripts_bucket}/etl/transform.py"
    }
    worker_type       = "G.2X"
    number_of_workers = 20
    max_capacity      = null
    timeout           = 60
    max_retries       = 2

    # Job parameters
    default_arguments = {
      "--job-language"           = "python"
      "--enable-metrics"         = "true"
      "--enable-continuous-cloudwatch-log" = "true"
      "--job-bookmark-option"    = "job-bookmark-enable"
      "--additional-python-modules" = "awswrangler==2.15.0"
    }
  }

  # Python Shell Job
  "python-quality" = {
    role_arn     = aws_iam_role.glue.arn
    glue_version = "1.0"
    command = {
      name    = "pythonshell"
      script  = "s3://${var.scripts_bucket}/quality/data_quality.py"
    }
    max_capacity = 0.0625
    timeout      = 30
    max_retries  = 1

    default_arguments = {
      "--job-language" = "python"
    }
  }

  # Ray Job for ML
  "ray-ml-job" = {
    role_arn     = aws_iam_role.glue.arn
    glue_version = "4.0"
    command = {
      name   = "glueetl"
      script = "s3://${var.scripts_bucket}/ml/train_model.py"
    }
    worker_type       = "Z.2X"
    number_of_workers = 10
    max_capacity      = null

    default_arguments = {
      "--job-language" = "python"
      "--ray-job-mode" = "multinode"
    }
  }
}
```

### 5. External Connections
JDBC connections to external data sources:

```hcl
glue_connections = {
  # RDS PostgreSQL Connection
  "rds-connection" = {
    connection_type = "JDBC"
    connection_properties = {
      JDBC_CONNECTION_URL = "jdbc:postgresql://${aws_rds_cluster.main.endpoint}:5432/${var.rds_database}"
      USERNAME            = "${var.rds_username}"
      PASSWORD            = aws_secretsmanager_secret_version.rds_password.secret_string
    }
    physical_connection_requirements = {
      availability_zone = data.aws_subnet.selected.availability_zone
      security_group_id_list = [aws_security_group.glue[0].id]
      subnet_id           = data.aws_subnet.selected.id
    }
  }

  # Redshift Connection
  "redshift-connection" = {
    connection_type = "JDBC"
    connection_properties = {
      JDBC_CONNECTION_URL = "jdbc:redshift://${aws_redshift_cluster.main.endpoint}:5439/${var.redshift_database}"
      USERNAME            = "${var.redshift_username}"
      PASSWORD            = aws_secretsmanager_secret_version.redshift_password.secret_string
    }
    physical_connection_requirements = {
      availability_zone      = data.aws_subnet.selected.availability_zone
      security_group_id_list = [aws_security_group.glue[0].id]
      subnet_id              = data.aws_subnet.selected.id
    }
  }
}
```

### 6. Workflow Orchestration
Complex data pipeline orchestration:

```hcl
glue_config = {
  workflows = {
    "data-pipeline" = {
      description = "Enterprise data processing pipeline"
      max_concurrent_runs = 1

      # Workflow tags
      tags = {
        Purpose    = "ETL"
        Criticality = "High"
      }
    }
  }

  triggers = {
    # Scheduled trigger to start crawlers
    "start-crawlers" = {
      workflow_name = "data-pipeline"
      type          = "SCHEDULED"
      schedule      = "cron(0 1 * * ? *)"
      actions       = ["s3-raw-data", "rds-source"]
    }

    # Conditional trigger after crawlers complete
    "start-etl" = {
      workflow_name = "data-pipeline"
      type          = "CONDITIONAL"
      predicate {
        logical_and = true
        conditions {
          job_name   = "s3-raw-data"
          state      = "SUCCEEDED"
        }
        conditions {
          job_name   = "rds-source"
          state      = "SUCCEEDED"
        }
      }
      actions = ["spark-transform"]
    }

    # Conditional trigger for quality checks
    "quality-check" = {
      workflow_name = "data-pipeline"
      type          = "CONDITIONAL"
      predicate {
        conditions {
          job_name = "spark-transform"
          state    = "SUCCEEDED"
        }
      }
      actions = ["python-quality"]
    }

    # Event-based trigger
    "event-trigger" = {
      workflow_name = "data-pipeline"
      type          = "EVENT_DATA"
      actions       = ["ray-ml-job"]

      # Event configuration for S3 put events
      event_batching_condition = {
        batch_window = 60
        batch_size   = 100
      }
    }
  }
}
```

### 7. Secrets Management
Secure credential storage:

```hcl
secrets_config = {
  "rds-credentials" = {
    description = "RDS PostgreSQL credentials for Glue connections"
    secret_string = jsonencode({
      username = var.rds_username
      password = var.rds_password
      host     = aws_rds_cluster.main.endpoint
      port     = 5432
      database = var.rds_database
    })

    tags = {
      Environment = var.environment
      DataStore   = "RDS"
    }
  }

  "redshift-credentials" = {
    description = "Redshift credentials for Glue connections"
    secret_string = jsonencode({
      username = var.redshift_username
      password = var.redshift_password
      host     = aws_redshift_cluster.main.endpoint
      port     = 5439
      database = var.redshift_database
    })

    tags = {
      Environment = var.environment
      DataStore   = "Redshift"
    }
  }
}
```

## Expected Results

### Resources Created
- **1 Glue Database**: Central metadata repository
- **4+ Glue Crawlers**: S3, RDS, Redshift, Delta Lake
- **3+ Glue Jobs**: Spark ETL, Python Shell, Ray jobs
- **1 Glue Workflow**: Data pipeline orchestration
- **4+ Triggers**: Scheduled, conditional, and event-based
- **2+ JDBC Connections**: RDS and Redshift
- **2+ Secrets**: Secure credential storage
- **1 Security Configuration**: Comprehensive encryption
- **1 IAM Role**: Enterprise execution role
- **1 Security Group**: VPC integration
- **Multiple CloudWatch**: Log groups and metrics

### Cost Estimate (Monthly)
- **Glue Crawlers**: ~$30-100 (depends on frequency and data size)
- **Glue Jobs**: ~$200-1000 (depends on DPU hours and job complexity)
- **Glue Database**: ~$1.00
- **Glue Workflow**: ~$1.00
- **CloudWatch Logs**: ~$10-50 (depends on log volume)
- **Data Transfer**: Varies by data movement
- **Storage**: Based on S3 and data catalog usage

## Usage Examples

### 1. Manual Workflow Execution
```bash
# Start the complete workflow
aws glue start_workflow_run --name data-pipeline

# Monitor workflow progress
aws glue get_workflow_runs --name data-pipeline --max-results 5

# View workflow run details
aws glue get_workflow-run --name data-pipeline --run-id <run-id>
```

### 2. Individual Job Execution
```bash
# Start Spark job
aws glue start-job-run --job-name spark-transform

# Start Python shell job
aws glue start-job-run --job-name python-quality

# Monitor job progress
aws glue get-job-runs --job-name spark-transform --max-results 5
```

### 3. Crawler Management
```bash
# Start specific crawler
aws glue start-crawler --name rds-source

# Check crawler status
aws glue get-crawler --name rds-source --query 'Crawler.State'

# Get crawler metrics
aws glue get-crawler-metrics --crawler-name-list rds-source
```

### 4. Query Processed Data
```sql
-- Query with Athena
SELECT * FROM "mycompany_prod_db.customer_data" LIMIT 100;

-- Query with Redshift Spectrum
SELECT COUNT(*) FROM spectrum_db.customer_transactions;

-- Join data from multiple sources
SELECT c.*, o.order_date
FROM mycompany_prod_db.customers c
JOIN mycompany_prod_db.orders o ON c.id = o.customer_id;
```

## Monitoring and Operations

### CloudWatch Monitoring
```bash
# Create metric filters for job monitoring
aws logs put-metric-filter --log-group-name /aws-glue/jobs/output \
  --filter-name "JobErrors" \
  --filter-pattern "[timestamp, request_id, job_name, level, message]" \
  --metric-transformations metricName=JobErrorCount,metricNamespace=GlueJobs,metricValue=1

# Set up alarms for job failures
aws cloudwatch put-metric-alarm --alarm-name "GlueJobFailures" \
  --alarm-description "Alert on Glue job failures" \
  --metric-name JobErrorCount --namespace GlueJobs \
  --statistic Sum --period 300 --threshold 3 --comparison-operator GreaterThanThreshold
```

### Performance Optimization
```bash
# Monitor DPU utilization
aws glue get-job-runs --job-name spark-transform --query 'JobRuns[].{JobName:JobName,DPUMax:MaxCapacity,ExecutionTime:ExecutionTime}'

# Analyze job metrics
aws cloudwatch get-metric-statistics --namespace AWS/Glue \
  --metric-name DPUSeconds --dimensions Name=JobName,Value=spark-transform \
  --start-time 2024-01-01T00:00:00Z --end-time 2024-01-01T23:59:59Z --period 3600
```
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0, < 7.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.40.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_glue_complete"></a> [glue\_complete](#module\_glue\_complete) | ../../ | n/a |
| <a name="module_rds"></a> [rds](#module\_rds) | sourcefuse/arc-db/aws | 4.0.2 |
| <a name="module_redshift"></a> [redshift](#module\_redshift) | sourcefuse/arc-redshift/aws | 0.0.1 |
| <a name="module_s3_data"></a> [s3\_data](#module\_s3\_data) | sourcefuse/arc-s3/aws | 0.0.7 |
| <a name="module_s3_logs"></a> [s3\_logs](#module\_s3\_logs) | sourcefuse/arc-s3/aws | 0.0.7 |
| <a name="module_s3_scripts"></a> [s3\_scripts](#module\_s3\_scripts) | sourcefuse/arc-s3/aws | 0.0.7 |

## Resources

| Name | Type |
|------|------|
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_subnets.private_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.arc_poc_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_authorized_accounts"></a> [authorized\_accounts](#input\_authorized\_accounts) | List of AWS account ARNs for cross-account Glue catalog access | `list(string)` | `[]` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment identifier | `string` | `"poc"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name prefix for resources | `string` | `"glue-complete"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace/organization identifier | `string` | `"arc"` | no |
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | AWS Organization ID for catalog resource policy condition | `string` | `""` | no |
| <a name="input_permissions_boundary_arn"></a> [permissions\_boundary\_arn](#input\_permissions\_boundary\_arn) | ARN of IAM permissions boundary to attach to the Glue role | `string` | `null` | no |
| <a name="input_rds_database"></a> [rds\_database](#input\_rds\_database) | RDS database name | `string` | `"testdb"` | no |
| <a name="input_rds_password"></a> [rds\_password](#input\_rds\_password) | RDS master password | `string` | `"ChangeMe123!"` | no |
| <a name="input_redshift_database"></a> [redshift\_database](#input\_redshift\_database) | Redshift database name | `string` | `"dev"` | no |
| <a name="input_redshift_password"></a> [redshift\_password](#input\_redshift\_password) | Redshift master password | `string` | n/a | yes |
| <a name="input_redshift_username"></a> [redshift\_username](#input\_redshift\_username) | Redshift username | `string` | `"admin"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region for resources | `string` | `"us-east-1"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to resources | `map(string)` | <pre>{<br/>  "Environment": "POC",<br/>  "ManagedBy": "Terraform",<br/>  "Project": "Glue Complete Example"<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_glue_connection_names"></a> [glue\_connection\_names](#output\_glue\_connection\_names) | Map of connection key to name |
| <a name="output_glue_crawler_names"></a> [glue\_crawler\_names](#output\_glue\_crawler\_names) | Map of crawler key to name |
| <a name="output_glue_database_name"></a> [glue\_database\_name](#output\_glue\_database\_name) | The name of the Glue catalog database |
| <a name="output_glue_iam_role_arn"></a> [glue\_iam\_role\_arn](#output\_glue\_iam\_role\_arn) | The ARN of the Glue IAM role |
| <a name="output_glue_job_names"></a> [glue\_job\_names](#output\_glue\_job\_names) | Map of job key to name |
| <a name="output_glue_secret_arns"></a> [glue\_secret\_arns](#output\_glue\_secret\_arns) | Map of Glue secret key to ARN |
| <a name="output_glue_security_configurations"></a> [glue\_security\_configurations](#output\_glue\_security\_configurations) | Map of security configuration key to name |
| <a name="output_glue_security_group_id"></a> [glue\_security\_group\_id](#output\_glue\_security\_group\_id) | The ID of the Glue security group |
| <a name="output_glue_workflows"></a> [glue\_workflows](#output\_glue\_workflows) | Map of workflow key to workflow object |
| <a name="output_rds_database_name"></a> [rds\_database\_name](#output\_rds\_database\_name) | The RDS database name |
| <a name="output_redshift_database_name"></a> [redshift\_database\_name](#output\_redshift\_database\_name) | The Redshift database name |
| <a name="output_s3_data_bucket"></a> [s3\_data\_bucket](#output\_s3\_data\_bucket) | The S3 bucket for Glue data |
| <a name="output_s3_logs_bucket"></a> [s3\_logs\_bucket](#output\_s3\_logs\_bucket) | The S3 bucket for Glue logs |
| <a name="output_s3_scripts_bucket"></a> [s3\_scripts\_bucket](#output\_s3\_scripts\_bucket) | The S3 bucket for Glue scripts |
<!-- END_TF_DOCS -->
