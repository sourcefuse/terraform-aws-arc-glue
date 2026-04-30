region      = "us-east-1"
namespace   = "arc"
environment = "poc"
name        = "glue-complete"

# RDS
rds_password = "ChangeMe123!"
rds_database = "testdb"

# Redshift
redshift_username = "admin"
redshift_password = "ChangeMe123!"
redshift_database = "dev"

# Cross-account / org (leave empty for single-account POC)
authorized_accounts = []
organization_id     = ""

tags = {
  Project     = "Glue Complete Example"
  Environment = "POC"
  ManagedBy   = "Terraform"
}
