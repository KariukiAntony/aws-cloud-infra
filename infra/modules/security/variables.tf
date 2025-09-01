variable "base_name" {
  description = "The base name for all resources"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the vpc"
  type        = string

}

variable "host_key_path" {
  description = "Path to public key for public instances"
  type        = string
}

variable "bastion_host_allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access public instance"
  type        = list(string)
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


variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {}
}

# --- Frontend s3 bucket ---
variable "frontend_bucket_id" {
  description = "ID of the bucket to host the frontend"
  type        = string
}

variable "frontend_bucket_arn" {
  description = "ARN of the bucket to host the frontend"
  type        = string
}