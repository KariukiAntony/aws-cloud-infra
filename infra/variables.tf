# ---- Root Module ---
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

# --- Networking module ---

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block"
  }
}

variable "enable_vpc_dns_support" {
  description = "Enable vpc dns support"
  type        = bool
  default     = true
}

variable "enable_vpc_dns_hostname" {
  description = "Enable vpc dns hostnames"
  type        = bool
  default     = true
}

variable "public_subnet_cidrs" {
  description = "The cidr blocks for the public subnets."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "The cidr blocks for the private subnets."
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Should be true to provision a NAT geteway."
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {}
}

# ---- Security Module ---
variable "host_key_path" {
  description = "Path to public key for public instances"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "bastion_host_allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access public instance"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allow_bastion_host_http_traffic" {
  description = "Whether to allow http traffic to bastion host"
  type        = bool
  default     = false
}

variable "allow_bastion_host_https_traffic" {
  description = "Whether to allow https traffic to bastion host"
  type        = bool
  default     = false
}

# ---- Compute ----
variable "bastion_instance_type" {
  description = "The instance type of the bastion host"
  type        = string
  default     = "t2.micro"
}

variable "bastion_data_script_path" {
  description = "Bastion data script path in relative to root dir"
}

variable "bastion_connection_key_path" {
  description = "Bastion SSH private key path"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "private_connection_key_path" {
  description = "Private instance SSH private key path"
  type        = string
  default     = "~/.ssh/id_rsa"
}