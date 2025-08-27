
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

variable "aliases" {
  description = "List of domain aliases for the distribution"
  type        = list(string)
}

variable "web_acl_id" {
  description = "AWS WAF web ACL ID to associate with the distribution"
  type        = string
  default     = ""

}
variable "origin_domain_name" {
  description = "Domain name of the origin (ALB DNS name)"
  type        = string
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
  default     = 120
}

variable "max_ttl" {
  description = "Maximum TTL for cached objects (seconds)"
  type        = number
  default     = 300
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

variable "origin_ssl_protocols" {
  description = "SSL protocols for origin"
  type        = list(string)
  default     = ["TLSv1.2"]
}

variable "origin_http_port" {
  description = "HTTP port for origin"
  type        = number
  default     = 80
}

variable "origin_https_port" {
  description = "HTTPS port for origin"
  type        = number
  default     = 443
}

variable "acm_certificate_arn" {
  description = "ARN of ACM certificate for custom domain (must be in us-east-1)"
  type        = string
  default     = ""
}

variable "allowed_methods" {
  description = "HTTP methods that CloudFront processes and forwards"
  type        = list(string)
  default     = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
}

variable "s3_bucket_prefix" {
  description = "Prefix for S3 access logs"
  type        = string
  default     = "cloudfront-logs/"
}

variable "base_name" {
  description = "Basename for all resources."
  type        = string
}


variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
