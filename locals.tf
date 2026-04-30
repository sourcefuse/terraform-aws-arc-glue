# Local variables for centralized logic
locals {
  # Create standardized resource names
  resource_prefix = "${var.namespace}-${var.environment}-${var.name}"

  # Extract nested configs for easier access
  iam_enabled = try(var.iam_config.create_role, true)

  # Conditional role creation
  create_iam_role = local.iam_enabled && var.iam_config.role_name == null

}
