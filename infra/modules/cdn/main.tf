
provider "aws" {
  region = "us-east-1"
  alias  = "us_east_1"
}

resource "random_id" "bucket_suffix" {
  byte_length = 6
}

# A bucket to store cloudfront logs
resource "aws_s3_bucket" "cloudfront_logs" {
  bucket = "${var.base_name}-cloudfront-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "main" {
  bucket = aws_s3_bucket.cloudfront_logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "example" {
  depends_on = [aws_s3_bucket_ownership_controls.main]

  bucket = aws_s3_bucket.cloudfront_logs.id
  acl    = "private"
}

# Cloudfront Origin Access control for frontend bucket
resource "aws_cloudfront_origin_access_control" "main" {
  provider                          = aws.us_east_1
  name                              = "${var.base_name}-oac"
  description                       = "Origin Access control for CloudFront to access S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "main" {
  provider            = aws.us_east_1
  enabled             = var.enabled
  is_ipv6_enabled     = var.is_ipv6_enabled
  default_root_object = var.default_root_object
  comment             = var.comment != "" ? var.comment : "CloudFront distribution for ${var.base_name}"
  price_class         = var.price_class
  web_acl_id          = var.web_acl_id
  aliases             = var.aliases

  # S3 Origin for frontend
  origin {
    domain_name              = var.s3_regional_domain_name
    origin_id                = "${var.base_name}-s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.main.id

  }

  default_cache_behavior {
    allowed_methods        = var.allowed_methods
    cached_methods         = var.cached_methods
    viewer_protocol_policy = var.viewer_protocol_policy
    compress               = var.compress
    target_origin_id       = "${var.base_name}-s3-origin"

    # Configure cache settings
    min_ttl     = var.min_ttl
    default_ttl = var.default_ttl
    max_ttl     = var.max_ttl

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # Custom error responses for SPA routing
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = var.custom_error_page_path
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = var.custom_error_page_path
  }

  viewer_certificate {
    cloudfront_default_certificate = var.acm_certificate_arn == "" ? true : false
    acm_certificate_arn            = var.acm_certificate_arn != "" ? var.acm_certificate_arn : null
    ssl_support_method             = var.acm_certificate_arn != "" ? var.ssl_support_method : null
    minimum_protocol_version       = var.acm_certificate_arn != "" ? var.minimum_protocol_version : null
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  logging_config {
    bucket          = aws_s3_bucket.cloudfront_logs.bucket_domain_name
    prefix          = var.s3_bucket_prefix
    include_cookies = false
  }

  wait_for_deployment = var.wait_for_deployment

  tags = merge(var.tags, {
    Name = "${var.base_name}-cdn"
  })
}
