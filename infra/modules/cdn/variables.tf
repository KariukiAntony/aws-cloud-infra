
variable "enabled" {
  description = "Whether the distribution is enabled to accept end user requests for content."
  type        = bool
}

variable "is_ipv6_enabled" {
  description = "Whether IPv6 is enabled for the distribution"
  type        = bool
}

variable "comment" {
  description = "Comment for the distribution"
  type        = string
}

variable "price_class" {
  description = "Price class for the distribution (PriceClass_All, PriceClass_200, PriceClass_100)"
  type        = string
}

variable "default_root_object" {
  description = "Object CloudFront will return on the root url."
  type        = string
}

variable "custom_error_page_path" {
  description = "Custom error response page."
  type        = string
}

variable "aliases" {
  description = "List of domain aliases for the distribution"
  type        = list(string)
}

variable "web_acl_id" {
  description = "AWS WAF web ACL ID to associate with the distribution"
  type        = string
}

variable "s3_regional_domain_name" {
  description = "Domain name of the origin (S3 bucket)"
  type        = string
}

variable "allowed_methods" {
  description = "HTTP methods that CloudFront processes and forwards"
  type        = list(string)
}

variable "cached_methods" {
  description = "HTTP methods for which CloudFront caches responses"
  type        = list(string)
}

variable "viewer_protocol_policy" {
  description = "Viewer protocol policy (allow-all, redirect-to-https, https-only)"
  type        = string
}

variable "compress" {
  description = "Whether to compress content automatically"
  type        = bool
}

variable "ssl_support_method" {
  description = "SSL support method (sni-only or vip)"
  type        = string
}

variable "minimum_protocol_version" {
  description = "Minimum SSL protocol version"
  type        = string
}

variable "wait_for_deployment" {
  description = "Wait for the distribution status to change from InProgress to Deployed"
  type        = bool
}

variable "default_ttl" {
  description = "Default TTL for cached objects (seconds)"
  type        = number
}

variable "max_ttl" {
  description = "Maximum TTL for cached objects (seconds)"
  type        = number
}

variable "min_ttl" {
  description = "Minimum TTL for cached objects (seconds)"
  type        = number
}

variable "origin_protocol_policy" {
  description = "Origin protocol policy (http-only, https-only, match-viewer)"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of ACM certificate for custom domain (must be in us-east-1)"
  type        = string
}

variable "s3_bucket_prefix" {
  description = "Prefix for S3 access logs"
  type        = string
}

variable "base_name" {
  description = "Basename for all resources."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
}
