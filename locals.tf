# Local variables for centralized logic
locals {
  # Create standardized resource names
  resource_prefix = "${var.namespace}-${var.environment}-${var.name}"

  # Standard tags merged with user-provided tags
  standard_tags = merge(
    {
      "ManagedBy"   = "Terraform"
      "Module"      = "aws-terraform-glue"
      "Namespace"   = var.namespace
      "Environment" = var.environment
      "Name"        = var.name
    },
    var.tags
  )

  # Extract nested configs for easier access
  iam_enabled = try(var.iam_config.create_role, true)

  # Conditional role creation
  create_iam_role = local.iam_enabled && var.iam_config.role_name == null

  # Security group enabled
  create_security_group = try(var.vpc_config.create_security_group, false)
}
