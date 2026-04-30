variable "region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "namespace" {
  description = "Namespace/organization identifier"
  type        = string
  default     = "example"
}

variable "environment" {
  description = "Environment identifier"
  type        = string
  default     = "dev"
}

variable "name" {
  description = "Name prefix for resources"
  type        = string
  default     = "glue"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Project     = "Glue Simple Example"
    Environment = "Development"
  }
}
