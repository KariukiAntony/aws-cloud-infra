resource "random_id" "bucket_suffix" {
  byte_length = 6
}

# A bucket to store cloudfront logs
resource "aws_s3_bucket" "cloudfront_logs" {
  bucket = "${var.base_name}-${random_id.bucket_suffix.hex}"
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

# CloudFront distribution
resource "aws_cloudfront_distribution" "main" {
  enabled         = var.enabled
  is_ipv6_enabled = var.is_ipv6_enabled
  comment         = var.comment != "" ? var.comment : "CloudFront distribution for ${var.base_name}"
  price_class     = var.price_class
  web_acl_id      = var.web_acl_id
  aliases         = var.aliases

  # S3 Origin for frontend
  origin {
    domain_name = var.origin_domain_name
    origin_id   = "${var.base_name}-origin"

    custom_origin_config {
      http_port              = var.origin_http_port
      https_port             = var.origin_https_port
      origin_protocol_policy = var.origin_protocol_policy
      origin_ssl_protocols   = var.origin_ssl_protocols
    }
  }

  default_cache_behavior {
    allowed_methods        = var.allowed_methods
    cached_methods         = var.cached_methods
    viewer_protocol_policy = var.viewer_protocol_policy
    compress               = var.compress
    target_origin_id       = "${var.base_name}-origin"

    # Configure cache settings
    default_ttl = var.default_ttl
    max_ttl     = var.max_ttl
    min_ttl     = var.min_ttl

    forwarded_values {
      query_string = false
      headers = [
        "Origin",
        "Host",
        "CloudFront-Viewer-Country",
        "CloudFront-Is-Mobile-Viewer",
        "CloudFront-Is-Tablet-Viewer",
        "CloudFront-Is-Desktop-Viewer"
      ]
      cookies {
        forward = "none"
      }
    }
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
