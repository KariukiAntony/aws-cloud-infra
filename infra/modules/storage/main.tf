# S3 bucket to host the fronted app

resource "random_id" "suffix" {
  byte_length = 6
}

# Bucket
resource "aws_s3_bucket" "frontend" {
  bucket        = "${var.base_name}-frontend-${random_id.suffix.hex}"
  force_destroy = true
  tags = merge(var.tags, {
    Purpose = "Frontend-app"
  })
}

# Bucket public access configuration
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket versioning
resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  versioning_configuration {
    status = var.enable_bucket_versioning ? "Enabled" : "Disabled"
  }
}

# Manage the old versions of the frontend
resource "aws_s3_bucket_lifecycle_configuration" "frontend" {
  count = var.enable_bucket_versioning ? 1 : 0

  bucket = aws_s3_bucket.frontend.id

  rule {
    id = "delete_old_versions"
    filter {}
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }

    # Clean up incomplete multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Encrypt and decrypt the bucket data
resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
