variable "region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^us-[a-z]+-[1-9]$", var.region)) || can(regex("^eu-[a-z]+-[1-9]$", var.region)) || can(regex("^ap-[a-z]+-[1-9]$", var.region))
    error_message = "The AWS region must be a valid AWS region format (e.g., us-east-1, eu-west-2)."
  }
}

variable "namespace" {
  description = "Namespace (organization) identifier for resources"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.namespace)) && length(var.namespace) <= 24
    error_message = "Namespace must be lowercase alphanumeric with hyphens, max 24 characters."
  }
}

variable "environment" {
  description = "Environment identifier (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.environment)) && length(var.environment) <= 24
    error_message = "Environment must be lowercase alphanumeric with hyphens, max 24 characters."
  }
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN to use for Glue encryption. If not provided, module will create its own KMS key but won't use it for security configurations to avoid circular dependencies."
  type        = string
  default     = null
}

variable "name" {
  description = "Name prefix for AWS Glue resources"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name)) && length(var.name) <= 64
    error_message = "Name must be lowercase alphanumeric with hyphens, max 64 characters."
  }
}

variable "tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "glue_config" {
  description = "AWS Glue configuration"
  type = object({
    create = optional(bool, true)

    # Glue Catalog Database
    database = optional(object({
      create      = optional(bool, true)
      name        = optional(string, "default_database")
      description = optional(string, "Default Glue database")
      create_table_default_permission = optional(object({
        create = optional(bool, false)
        permissions = optional(list(object({
          principal   = map(string)
          permissions = list(string)
        })), [])
      }), {})
    }), {})

    # Glue Workflows
    workflows = optional(map(object({
      description         = optional(string, "")
      max_concurrent_runs = optional(number, null)
    })), {})

    # Glue Triggers
    triggers = optional(map(object({
      description   = optional(string, "")
      workflow_name = optional(string, null)
      type          = string # SCHEDULED, CONDITIONAL, EVENT_DATA, ON_DEMAND
      schedule      = optional(string, null)
      predicate = optional(object({
        logical = optional(string, "AND")
        conditions = list(object({
          job_name     = optional(string, null)
          crawler_name = optional(string, null)
          state        = optional(string, null)
          crawl_state  = optional(string, null)
        }))
      }), null)
      actions = list(object({
        job_name     = optional(string, null)
        arguments    = optional(map(string), null)
        timeout      = optional(number, null)
        crawler_name = optional(string, null)
      }))
      event_batching_condition = optional(object({
        batch_window = optional(number, null)
        batch_size   = optional(number, null)
      }), null)
    })), {})

    # Glue Classifiers
    classifiers = optional(map(object({
      grok_classifier = optional(object({
        name            = string
        classification  = string
        grok_pattern    = string
        custom_patterns = optional(map(string), {})
      }), null)
      json_classifier = optional(object({
        name      = string
        json_path = string
      }), null)
      xml_classifier = optional(object({
        name           = string
        classification = string
        row_tag        = string
      }), null)
      csv_classifier = optional(object({
        name                   = string
        delimiter              = optional(string, ",")
        quote_char             = optional(string, "\"")
        contains_header        = optional(string, "UNKNOWN") # PRESENT, ABSENT, UNKNOWN
        header                 = optional(list(string), [])
        disable_value_trimming = optional(bool, false)
        allow_single_quotes    = optional(bool, false)
      }), null)
    })), {})

    # Glue Dev Endpoints
    dev_endpoints = optional(map(object({
      description               = optional(string, "")
      role_arn                  = optional(string, null)
      public_key                = string
      number_of_nodes           = optional(number, 5)
      worker_type               = optional(string, "G.1X") # Standard, G.1X, G.2X
      glue_version              = optional(string, "2.0")
      number_of_workers         = optional(number, 2)
      extra_python_libs_s3_path = optional(string, null)
      extra_jars_s3_path        = optional(string, null)
      security_configuration    = optional(string, null)
    })), {})

    # Glue Security Configurations
    security_configurations = optional(map(object({
      encryption_configuration = object({
        s3_encryption = optional(object({
          s3_encryption_mode = optional(string, "SSE-KMS") # SSE-KMS, SSE-S3, DISABLED
          kms_key_arn        = optional(string, null)
        }), {})
        cloudwatch_encryption = optional(object({
          cloudwatch_encryption_mode = optional(string, "SSE-KMS") # SSE-KMS, DISABLED
          kms_key_arn                = optional(string, null)
        }), {})
        job_bookmarks_encryption = optional(object({
          job_bookmarks_encryption_mode = optional(string, "CSE-KMS") # CSE-KMS, DISABLED
          kms_key_arn                   = optional(string, null)
        }), {})
      })
    })), {})

    # Data Catalog Encryption Settings
    catalog_encryption_settings = optional(object({
      create                         = optional(bool, false)
      connection_password_encryption = optional(bool, true)
      at_rest_encryption = optional(object({
        catalog_encryption_mode = optional(string, "SSE-KMS") # SSE-KMS, SSE-KMS-DIRECT-QUERY, DISABLED
        kms_key_arn             = optional(string, null)
      }), {})
      s3_encryption = optional(object({
        s3_encryption_mode = optional(string, "SSE-KMS") # SSE-KMS, SSE-S3, DISABLED
        kms_key_arn        = optional(string, null)
      }), {})
    }), {})

    # Data Catalog Resource Policy
    catalog_resource_policy = optional(object({
      create      = optional(bool, false)
      policy      = optional(string, "")
      description = optional(string, "Glue Data Catalog Resource Policy")
    }), {})

    # Glue Partition Index
    partition_indexes = optional(map(object({
      database_name = string
      table_name    = string
      index_name    = string
      keys          = list(string)
    })), {})
  })
  default = {}
}

variable "iam_config" {
  description = "IAM configuration for Glue resources"
  type = object({
    create_role            = optional(bool, true)
    role_name              = optional(string, null)
    role_description       = optional(string, "AWS Glue IAM Role")
    role_policies          = optional(map(string), {}) # Map of policy names to policy ARNs
    create_custom_policy   = optional(bool, false)
    custom_policy_name     = optional(string, null)
    custom_policy_document = optional(string, null)
    permissions_boundary   = optional(string, null)
    trusted_role_arns      = optional(list(string), [])
  })
  default = {}
}

variable "vpc_config" {
  description = "VPC configuration for Glue connections"
  type = object({
    create_security_group      = optional(bool, false)
    vpc_id                     = optional(string, null)
    security_group_name        = optional(string, null)
    security_group_description = optional(string, "Glue Security Group")
    ingress_rules = optional(map(object({
      description     = string
      from_port       = number
      to_port         = number
      protocol        = string
      cidr_blocks     = optional(list(string), [])
      security_groups = optional(list(string), [])
    })), {})
    egress_rules = optional(map(object({
      description     = string
      from_port       = number
      to_port         = number
      protocol        = string
      cidr_blocks     = optional(list(string), [])
      security_groups = optional(list(string), [])
    })), {})
    subnet_ids = optional(list(string), [])
  })
  default = {}
}

variable "glue_crawlers" {
  description = "Glue crawlers. Kept separate from glue_config to avoid for_each unknown-value issues when targets contain apply-time values."
  type = map(object({
    database_name = string
    description   = optional(string, "")
    role_arn      = optional(string, null)
    schedule      = optional(string, null)
    classifiers   = optional(list(string), [])
    configuration = optional(string, null)
    table_prefix  = optional(string, "")
    schema_change_policy = optional(object({
      delete_behavior = optional(string, "LOG")
      update_behavior = optional(string, "UPDATE_IN_DATABASE")
    }), {})
    recrawl_policy = optional(object({
      recrawl_behavior = optional(string, "CRAWL_NEW_FOLDERS_ONLY")
    }), {})
    lineage_configuration = optional(object({
      crawler_lineage_settings = optional(string, "ENABLE")
    }), {})
    targets = object({
      s3_targets = optional(list(object({
        path                = string
        exclusions          = optional(list(string), [])
        connection_name     = optional(string, null)
        sample_size         = optional(number, null)
        event_queue_arn     = optional(string, null)
        dlq_event_queue_arn = optional(string, null)
      })), [])
      jdbc_targets = optional(list(object({
        connection_name = string
        path            = optional(string, null)
        exclusions      = optional(list(string), [])
      })), [])
      mongo_db_targets = optional(list(object({
        connection_name = string
        path            = optional(string, null)
        scan_all        = optional(bool, null)
      })), [])
      delta_targets = optional(list(object({
        connection_name = optional(string, null)
        delta_tables    = optional(list(string), [])
        write_manifest  = optional(bool, null)
      })), [])
      catalog_targets = optional(list(object({
        database_name       = string
        tables              = list(string)
        event_queue_arn     = optional(string, null)
        dlq_event_queue_arn = optional(string, null)
      })), [])
    })
  }))
  default = {}
}

variable "glue_jobs" {
  description = "Glue jobs. Kept separate from glue_config to avoid for_each unknown-value issues when script_location contains apply-time values."
  type = map(object({
    description = optional(string, "")
    role_arn    = optional(string, null)
    command = object({
      name            = string
      script_location = string
      python_version  = optional(string, "3")
      runtime         = optional(string, null)
    })
    default_arguments         = optional(map(string), {})
    non_overridable_arguments = optional(map(string), {})
    execution_property = optional(object({
      max_concurrent_runs = optional(number, 1)
    }), {})
    max_retries       = optional(number, 0)
    timeout           = optional(number, null)
    max_capacity      = optional(number, null)
    number_of_workers = optional(number, null)
    worker_type       = optional(string, null)
    glue_version      = optional(string, "4.0")
    execution_class   = optional(string, null)
  }))
  default = {}
}

variable "glue_connections" {
  description = "Glue connections to create. Kept separate from glue_config to avoid for_each unknown value issues when connection_properties contain apply-time values."
  type = map(object({
    connection_type       = string
    description           = optional(string, "")
    connection_properties = map(string)
    physical_connection_requirements = optional(object({
      availability_zone      = optional(string, null)
      subnet_id              = optional(string, null)
      security_group_id_list = optional(list(string), [])
    }), null)
  }))
  default = {}
}

variable "secrets_config" {
  description = "Secrets Manager configuration for storing credentials"
  type = object({
    secrets = optional(map(object({
      name          = optional(string, null)
      description   = optional(string, "")
      secret_string = optional(string, null)
    })), {})
  })
  default = {}
}
