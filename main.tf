# ============================================================
# Security Group (Optional)
# ============================================================
resource "aws_security_group" "glue" {
  count = local.create_security_group ? 1 : 0

  name_prefix = try(var.vpc_config.security_group_name, "${local.resource_prefix}-glue-")
  description = try(var.vpc_config.security_group_description, "Glue Security Group")
  vpc_id      = var.vpc_config.vpc_id

  tags = merge(local.standard_tags, {
    Name = "${local.resource_prefix}-glue"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================
# IAM Role
# ============================================================
resource "aws_iam_role" "glue" {
  count = local.create_iam_role ? 1 : 0

  name                 = try(var.iam_config.role_name, "${local.resource_prefix}-glue-role")
  description          = try(var.iam_config.role_description, "AWS Glue IAM Role")
  assume_role_policy   = data.aws_iam_policy_document.assume_role[0].json
  permissions_boundary = try(var.iam_config.permissions_boundary, null)
  tags                 = local.standard_tags

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "assume_role" {
  count = local.create_iam_role ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }

    dynamic "principals" {
      for_each = try(var.iam_config.trusted_role_arns, [])
      content {
        type        = "AWS"
        identifiers = [principals.value]
      }
    }
  }
}

# Attach AWS managed policies
resource "aws_iam_role_policy_attachment" "glue_basic" {
  count = local.create_iam_role ? 1 : 0

  role       = aws_iam_role.glue[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "glue_s3" {
  count = local.create_iam_role ? 1 : 0

  role       = aws_iam_role.glue[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Attach additional policies
resource "aws_iam_role_policy_attachment" "glue_custom" {
  for_each = local.create_iam_role ? try(var.iam_config.role_policies, {}) : {}

  role       = aws_iam_role.glue[0].name
  policy_arn = each.value
}

# ============================================================
# Glue Database
# ============================================================
resource "aws_glue_catalog_database" "main" {
  # Only create database if database config is provided and create flag is true
  count = try(var.glue_config.database.create, true) ? 1 : 0

  name        = try(var.glue_config.database.name, "default_database")
  description = try(var.glue_config.database.description, "Default Glue database")

  tags = local.standard_tags
}

# ============================================================
# Glue Crawlers
# ============================================================
resource "aws_glue_crawler" "main" {
  for_each = var.glue_crawlers

  database_name = each.value.database_name
  name          = "${local.resource_prefix}-${each.key}"
  role          = coalesce(try(each.value.role_arn, null), local.create_iam_role ? aws_iam_role.glue[0].arn : null)

  description   = try(each.value.description, "")
  classifiers   = try(each.value.classifiers, [])
  configuration = try(each.value.configuration, null)
  table_prefix  = try(each.value.table_prefix, "")

  dynamic "s3_target" {
    for_each = try(each.value.targets.s3_targets, [])
    content {
      path = s3_target.value.path
    }
  }

  dynamic "jdbc_target" {
    for_each = try(each.value.targets.jdbc_targets, [])
    content {
      connection_name = jdbc_target.value.connection_name
      path            = try(jdbc_target.value.path, null)
      exclusions      = try(jdbc_target.value.exclusions, [])
    }
  }

  dynamic "mongodb_target" {
    for_each = try(each.value.targets.mongo_db_targets, [])
    content {
      connection_name = mongodb_target.value.connection_name
      path            = try(mongodb_target.value.path, null)
      scan_all        = try(mongodb_target.value.scan_all, null)
    }
  }

  dynamic "delta_target" {
    for_each = try(each.value.targets.delta_targets, [])
    content {
      connection_name = try(delta_target.value.connection_name, null)
      delta_tables    = try(delta_target.value.delta_tables, [])
      write_manifest  = try(delta_target.value.write_manifest, null)
    }
  }

  dynamic "catalog_target" {
    for_each = try(each.value.targets.catalog_targets, [])
    content {
      database_name = catalog_target.value.database_name
      tables        = catalog_target.value.tables
    }
  }

  tags = merge(local.standard_tags, try(each.value.tags, {}))

  depends_on = [aws_glue_connection.main]
}

# ============================================================
# Glue Jobs
# ============================================================
resource "aws_glue_job" "main" {
  for_each = var.glue_jobs

  name     = "${local.resource_prefix}-${each.key}"
  role_arn = coalesce(try(each.value.role_arn, null), local.create_iam_role ? aws_iam_role.glue[0].arn : null)

  description       = try(each.value.description, "")
  glue_version      = try(each.value.glue_version, "4.0")
  max_retries       = try(each.value.max_retries, 0)
  timeout           = try(each.value.timeout, null)
  max_capacity      = try(each.value.max_capacity, null)
  number_of_workers = try(each.value.number_of_workers, null)
  worker_type       = try(each.value.worker_type, null)
  execution_class   = try(each.value.execution_class, null)

  command {
    name            = each.value.command.name
    script_location = each.value.command.script_location
    python_version  = try(each.value.command.python_version, "3")
    runtime         = try(each.value.command.runtime, null)
  }

  default_arguments = try(each.value.default_arguments, {})

  tags = local.standard_tags
}

# ============================================================
# Glue Workflows
# ============================================================
resource "aws_glue_workflow" "main" {
  for_each = try(var.glue_config.workflows, {})

  name                = "${local.resource_prefix}-${each.key}"
  description         = try(each.value.description, "")
  max_concurrent_runs = try(each.value.max_concurrent_runs, null)

  tags = local.standard_tags
}

# ============================================================
# Glue Triggers
# ============================================================
resource "aws_glue_trigger" "main" {
  for_each = try(var.glue_config.triggers, {})

  name          = "${local.resource_prefix}-${each.key}"
  type          = each.value.type
  description   = try(each.value.description, "")
  schedule      = try(each.value.schedule, null)
  workflow_name = try(each.value.workflow_name, null)

  dynamic "predicate" {
    for_each = try(each.value.predicate, null) != null ? [each.value.predicate] : []
    content {
      logical = try(predicate.value.logical, "AND")
      dynamic "conditions" {
        for_each = predicate.value.conditions
        content {
          job_name     = try(conditions.value.job_name, null)
          crawler_name = try(conditions.value.crawler_name, null)
          state        = try(conditions.value.state, null)
          crawl_state  = try(conditions.value.crawl_state, null)
        }
      }
    }
  }

  dynamic "actions" {
    for_each = each.value.actions
    content {
      job_name     = try(actions.value.job_name, null)
      crawler_name = try(actions.value.crawler_name, null)
      arguments    = try(actions.value.arguments, null)
      timeout      = try(actions.value.timeout, null)
    }
  }

  tags = local.standard_tags
}

# ============================================================
# Glue Connections
# ============================================================
resource "aws_glue_connection" "main" {
  for_each = var.glue_connections

  name            = "${local.resource_prefix}-${each.key}"
  description     = try(each.value.description, "")
  connection_type = each.value.connection_type

  connection_properties = each.value.connection_properties

  dynamic "physical_connection_requirements" {
    for_each = try(each.value.physical_connection_requirements, null) != null ? [each.value.physical_connection_requirements] : []
    content {
      availability_zone      = try(physical_connection_requirements.value.availability_zone, null)
      subnet_id              = try(physical_connection_requirements.value.subnet_id, null)
      security_group_id_list = compact(try(physical_connection_requirements.value.security_group_id_list, []))
    }
  }
}

# ============================================================
# Glue Classifiers
# ============================================================
resource "aws_glue_classifier" "json" {
  for_each = { for k, v in try(var.glue_config.classifiers, {}) : k => v if try(v.json_classifier, null) != null }

  name = "${local.resource_prefix}-${each.key}"
  json_classifier {
    json_path = each.value.json_classifier.json_path
  }
}

resource "aws_glue_classifier" "csv" {
  for_each = { for k, v in try(var.glue_config.classifiers, {}) : k => v if try(v.csv_classifier, null) != null }

  name = "${local.resource_prefix}-${each.key}"
  csv_classifier {
    delimiter              = try(each.value.csv_classifier.delimiter, ",")
    quote_symbol           = try(each.value.csv_classifier.quote_char, "\"")
    contains_header        = try(each.value.csv_classifier.contains_header, "UNKNOWN")
    header                 = try(each.value.csv_classifier.header, [])
    disable_value_trimming = try(each.value.csv_classifier.disable_value_trimming, false)
    allow_single_column    = try(each.value.csv_classifier.allow_single_quotes, false)
  }
}

resource "aws_glue_classifier" "grok" {
  for_each = { for k, v in try(var.glue_config.classifiers, {}) : k => v if try(v.grok_classifier, null) != null }

  name = "${local.resource_prefix}-${each.key}"
  grok_classifier {
    classification  = each.value.grok_classifier.classification
    grok_pattern    = each.value.grok_classifier.grok_pattern
    custom_patterns = try(join("\n", [for k, v in each.value.grok_classifier.custom_patterns : "${k} ${v}"]), null)
  }
}

resource "aws_glue_classifier" "xml" {
  for_each = { for k, v in try(var.glue_config.classifiers, {}) : k => v if try(v.xml_classifier, null) != null }

  name = "${local.resource_prefix}-${each.key}"
  xml_classifier {
    classification = each.value.xml_classifier.classification
    row_tag        = each.value.xml_classifier.row_tag
  }
}

# ============================================================
# Secrets Manager (Optional)
# ============================================================
resource "aws_secretsmanager_secret" "main" {
  for_each = try(var.secrets_config.secrets, {})

  name        = try(each.value.name, "${local.resource_prefix}-${each.key}")
  description = try(each.value.description, "")
  tags        = local.standard_tags
}

resource "aws_secretsmanager_secret_version" "main" {
  for_each = aws_secretsmanager_secret.main

  secret_id     = aws_secretsmanager_secret.main[each.key].id
  secret_string = var.secrets_config.secrets[each.key].secret_string
}

# ============================================================
# Glue Security Configurations
# ============================================================
resource "aws_glue_security_configuration" "main" {
  for_each = try(var.glue_config.security_configurations, {})

  name = "${local.resource_prefix}-${each.key}"

  encryption_configuration {
    s3_encryption {
      s3_encryption_mode = try(each.value.encryption_configuration.s3_encryption.s3_encryption_mode, "DISABLED")
      kms_key_arn        = try(var.kms_key_arn, each.value.encryption_configuration.s3_encryption.kms_key_arn, null)
    }

    cloudwatch_encryption {
      cloudwatch_encryption_mode = try(each.value.encryption_configuration.cloudwatch_encryption.cloudwatch_encryption_mode, "DISABLED")
      kms_key_arn                = try(var.kms_key_arn, each.value.encryption_configuration.cloudwatch_encryption.kms_key_arn, null)
    }

    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = try(each.value.encryption_configuration.job_bookmarks_encryption.job_bookmarks_encryption_mode, "DISABLED")
      kms_key_arn                   = try(var.kms_key_arn, each.value.encryption_configuration.job_bookmarks_encryption.kms_key_arn, null)
    }
  }
}
