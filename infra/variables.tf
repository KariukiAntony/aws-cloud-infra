variable "region" {
  description = "The region to create resources"
  type        = string
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "aws-cloud-infra"
}

variable "environment" {
  description = "Environment name. One of dev, staging, prod"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: prod, staging, dev."
  }
}

variable "enable_bucket_versioning" {
  description = "S3 Bucket versioning for state history"
  type        = bool
  default     = true
}

variable "state_version_retention_days" {
  description = "Number of days to retain old state file versions"
  type        = number
  default     = 90
}