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

## Troubleshooting

### Common Issues

#### 1. Crawler Fails with Access Denied
**Problem**: Crawler cannot access S3 bucket
**Solution**: Ensure IAM role has S3 permissions and bucket policy allows access

#### 2. No Tables Discovered
**Problem**: Crawler runs but creates no tables
**Solution**:
- Verify S3 path is correct
- Check data format is supported (CSV, JSON, Parquet, etc.)
- Ensure bucket contains data files

#### 3. Crawler Timeout
**Problem**: Crawler times out on large datasets
**Solution**:
```hcl
glue_crawlers = {
  "s3-crawler" = {
    # Increase timeout
    timeouts = {
      create = "60m"
    }
  }
}
```

### Getting Help

If you encounter issues:
1. Check CloudWatch Logs: `/aws-glue/crawlers/output`
2. Review IAM permissions in the AWS Console
3. Verify S3 bucket exists and is accessible
4. Check Terraform logs for detailed error messages

## Cleanup

### Remove All Resources
```bash
terraform destroy
```

### Manual Cleanup (if needed)
```bash
# Delete Glue database (must be empty)
aws glue delete-database --name mycompany_dev_simple_db

# Delete crawler
aws glue delete-crawler --name mycompany_dev_simple-s3-crawler
```

## Next Steps

### Advanced Features
Once comfortable with the simple example, explore the [Complete Example](../complete/) for:

- **Multiple Job Types**: Spark ETL, Python Shell, Ray jobs
- **Advanced Crawlers**: JDBC, MongoDB, Delta Lake sources
- **Workflow Orchestration**: Complex multi-step pipelines
- **Custom Triggers**: Scheduled and event-based execution
- **External Connections**: RDS, Redshift, MongoDB integration
- **Enhanced Security**: KMS encryption, VPC integration
- **Advanced Monitoring**: CloudWatch alarms and metrics

### Production Considerations
- **High Availability**: Multi-region deployment strategies
- **Disaster Recovery**: Backup and restore procedures
- **Security**: VPC deployment, encryption at rest
- **Monitoring**: Comprehensive alerting and dashboards
- **Cost Optimization**: Right-sizing resources and execution classes

### Additional Resources
- [Main Module Documentation](../../README.md)
- [Complete Usage Guide](../../docs/module-usage-guide/README.md)
- [AWS Glue Documentation](https://docs.aws.amazon.com/glue/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## Contributing

Found an issue or want to improve this example? Please:
1. Check existing [GitHub Issues](https://github.com/sourcefuse/terraform-aws-arc-glue/issues)
2. Create a new issue with details
3. Submit a pull request with your improvements

## License

This example is part of the terraform-aws-arc-glue module, licensed under the Apache 2.0 License.
