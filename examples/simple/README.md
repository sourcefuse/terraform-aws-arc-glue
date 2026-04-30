# Simple Glue Example

This example demonstrates the simplest way to use the AWS Glue module for basic data catalog and ETL operations. It creates a minimal but functional Glue infrastructure perfect for getting started with data lake implementations.

## Overview

This example deploys a foundational AWS Glue setup including:
- **Glue Data Catalog Database**: Central metadata repository
- **S3 Crawler**: Automated data discovery from S3
- **IAM Role**: Execution role with appropriate permissions
- **CloudWatch Logging**: Basic monitoring and logging
- **Security Configuration**: Basic encryption settings

## Prerequisites

Before running this example, ensure you have:

- **AWS Account**: With appropriate permissions
- **S3 Bucket**: Existing bucket containing data to catalog
- **Terraform**: Version 1.5 or higher installed
- **AWS CLI**: Configured with valid credentials
- **Basic Knowledge**: Understanding of AWS Glue concepts

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0, < 7.0.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_glue"></a> [glue](#module\_glue) | ../../ | n/a |
| <a name="module_s3_bucket"></a> [s3\_bucket](#module\_s3\_bucket) | sourcefuse/arc-s3/aws | 0.0.7 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | Environment identifier | `string` | `"dev"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name prefix for resources | `string` | `"glue"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace/organization identifier | `string` | `"example"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region for resources | `string` | `"us-east-1"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to resources | `map(string)` | <pre>{<br/>  "Environment": "Development",<br/>  "Project": "Glue Simple Example"<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_crawler_names"></a> [crawler\_names](#output\_crawler\_names) | Glue crawler names |
| <a name="output_database_name"></a> [database\_name](#output\_database\_name) | Glue database name |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | IAM role ARN |
| <a name="output_resource_prefix"></a> [resource\_prefix](#output\_resource\_prefix) | Resource prefix used |
| <a name="output_s3_bucket_arn"></a> [s3\_bucket\_arn](#output\_s3\_bucket\_arn) | S3 bucket ARN |
| <a name="output_s3_bucket_id"></a> [s3\_bucket\_id](#output\_s3\_bucket\_id) | S3 bucket ID for data storage |
<!-- END_TF_DOCS -->

## Quick Start

### 1. Clone and Navigate
```bash
git clone https://github.com/sourcefuse/terraform-aws-arc-glue.git
cd terraform-aws-arc-glue/example/simple
```

### 2. Configure Variables
Edit `terraform.tfvars` with your specific values:

```hcl
region      = "us-east-1"
namespace   = "mycompany"
environment = "dev"
name        = "simple-glue"

# S3 Configuration
data_bucket = "my-existing-data-bucket"  # Your data bucket
```

### 3. Initialize and Deploy
```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy the infrastructure
terraform apply
```

### 4. Verify Deployment
```bash
# Check Glue database
aws glue get-database --name mycompany_dev_simple

# List all crawlers
aws glue list-crawlers

# Get crawler details
aws glue get-crawler --name mycompany_dev_simple-s3-crawler

# Start the crawler manually
aws glue start-crawler --name mycompany_dev_simple-s3-crawler
```

## Configuration Details

### Main Components

#### 1. Data Catalog Database
```hcl
glue_config = {
  database = {
    create = true
    name   = "${var.namespace}_${var.environment}_db"
  }
}
```
Creates a centralized metadata repository for all your data assets.

#### 2. S3 Data Crawler
```hcl
glue_crawlers = {
  "s3-crawler" = {
    database_name = "${var.namespace}_${var.environment}_db"
    role_arn      = aws_iam_role.glue.arn
    targets = {
      s3_targets = [{
        path = "s3://${var.data_bucket}/"
      }]
    }
  }
}
```
Automatically discovers and catalogs data stored in S3.

#### 3. IAM Execution Role
```hcl
iam_config = {
  create_role = true
  role_policies = {
    "AmazonS3FullAccess" = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  }
}
```
Provides necessary permissions for Glue operations.

## Expected Results

### Resources Created
- **1 Glue Database**: Metadata repository
- **1 Glue Crawler**: S3 data discovery
- **1 IAM Role**: Glue execution role
- **1 Security Configuration**: Encryption settings
- **CloudWatch Log Groups**: Job monitoring

### Cost Estimate
- **Glue Crawler**: ~$0.30 per crawl (varies by data size)
- **Glue Database**: $1.00 per month
- **Data Storage**: Based on your S3 usage
- **CloudWatch Logs**: Minimal cost for logs

## Usage Examples

### 1. Manual Crawler Execution
```bash
# Start the crawler
aws glue start-crawler --name mycompany_dev_simple-s3-crawler

# Check crawler status
aws glue get-crawler --name mycompany_dev_simple-s3-crawler --query 'Crawler.State'

# View crawler logs
aws logs tail /aws-glue/crawlers/output --follow
```

### 2. Query Cataloged Data with Athena
```sql
-- Once crawler completes, query with Athena
SELECT * FROM "mycompany_dev_simple_db"."my_table" LIMIT 10;
```

### 3. Monitor Crawler Runs
```bash
# Get crawler metrics
aws glue get-crawler-metrics --crawler-name-list mycompany_dev_simple-s3-crawler

# View recent crawler runs
aws glue get-crawler-runs --crawler-name mycompany_dev_simple-s3-crawler --max-results 5
```

## Verification Steps

### 1. Database Verification
```bash
aws glue get-databases
# Should show your database: mycompany_dev_simple_db
```

### 2. Crawler Verification
```bash
aws glue get-crawler --name mycompany_dev_simple-s3-crawler
# Should show crawler details with 'State': 'READY'
```

### 3. Data Catalog Verification
After running the crawler, verify tables were created:
```bash
aws glue get-tables --database-name mycompany_dev_simple_db
# Should show discovered tables from your S3 data
```
