variable "base_name" {
  description = "The basename for all resources"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "enable_bucket_versioning" {
  description = "Whether to setup versioning in the fronted bucket"
  type        = bool
}

variable "noncurrent_version_expiration_days" {
  description = "Days to keep non-current versions"
  type        = number
}