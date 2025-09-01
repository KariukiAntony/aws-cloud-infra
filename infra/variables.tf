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

variable "instance_type" {
  description = "Instance type for your application servers"
  type        = string
}

variable "enable_alb_deletion_protection" {
  description = "Disable the deletion of load balancer via AWS API"
  type        = bool
  default     = false
}

variable "enable_monitoring" {
  description = "Enable EC2 detailed monitoring"
  type        = bool
  default     = true
}

variable "template_data_script" {
  description = "Launch template data script path in relative to root dir"
  type        = string
}

variable "min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
}

variable "max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
}

variable "desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
}

variable "scaling_adjustment" {
  description = "Number of instances by which to scale"
  type        = number
}


# ---- Bastion ----
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

# ---- dns-ssl ----
variable "domain_name" {
  description = "The domain name of your application"
  type        = string
}

# ---- Monitoring ----
variable "ec2_cloudwatch_log_group" {
  description = "The log group for ec2 instances"
  type        = string
}

variable "high_cpu_threshold" {
  description = "The maximum threshold to trigger auto scaling"
  type        = number
}

variable "high_memory_threshold" {
  description = "The maximum memory threshold to trigger auto scaling"
  type        = number
}

variable "notification_email" {
  description = "Email to receive notifications"
  type        = string
}

# ---- CDN -----

variable "enabled" {
  description = "Whether the distribution is enabled to accept end user requests for content."
  type        = bool
  default     = true
}

variable "is_ipv6_enabled" {
  description = "Whether IPv6 is enabled for the distribution"
  type        = bool
  default     = true
}

variable "default_root_object" {
  description = "Object CloudFront will return on the root url."
  type        = string
  default     = "/index.html"
}

variable "custom_error_page_path" {
  description = "Custom error response page."
  type        = string
  default     = "/error.html"
}

variable "comment" {
  description = "Comment for the distribution"
  type        = string
  default     = ""
}

variable "price_class" {
  description = "Price class for the distribution (PriceClass_All, PriceClass_200, PriceClass_100)"
  type        = string
  default     = "PriceClass_All"
}

variable "web_acl_id" {
  description = "AWS WAF web ACL ID to associate with the distribution"
  type        = string
  default     = ""
}


variable "s3_bucket_prefix" {
  description = "Prefix for S3 CloudFront logs"
  type        = string
}

variable "allowed_methods" {
  description = "HTTP methods that CloudFront processes and forwards"
  type        = list(string)
  default     = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
}

variable "cached_methods" {
  description = "HTTP methods for which CloudFront caches responses"
  type        = list(string)
  default     = ["GET", "HEAD"]
}

variable "viewer_protocol_policy" {
  description = "Viewer protocol policy (allow-all, redirect-to-https, https-only)"
  type        = string
  default     = "redirect-to-https"
}

variable "compress" {
  description = "Whether to compress content automatically"
  type        = bool
  default     = true
}

variable "ssl_support_method" {
  description = "SSL support method (sni-only or vip)"
  type        = string
  default     = "sni-only"
}

variable "minimum_protocol_version" {
  description = "Minimum SSL protocol version"
  type        = string
  default     = "TLSv1.2_2021"
}

variable "wait_for_deployment" {
  description = "Wait for the distribution status to change from InProgress to Deployed"
  default     = false
}

variable "default_ttl" {
  description = "Default TTL for cached objects (seconds)"
  type        = number
  default     = 3600
}

variable "max_ttl" {
  description = "Maximum TTL for cached objects (seconds)"
  type        = number
  default     = 86400
}

variable "min_ttl" {
  description = "Minimum TTL for cached objects (seconds)"
  type        = number
  default     = 0
}


variable "origin_protocol_policy" {
  description = "Origin protocol policy (http-only, https-only, match-viewer)"
  type        = string
  default     = "https-only"
}

# ---- Storage -----
variable "enable_frontend_bucket_versioning" {
  description = "Whether to setup versioning in the fronted bucket"
  type        = bool
  default     = false
}

variable "noncurrent_version_expiration_days" {
  description = "Days to keep non-current versions"
  type        = number
  default     = 30
  validation {
    condition     = var.noncurrent_version_expiration_days > 0
    error_message = "Expiration days must be greater than 0."
  }
}