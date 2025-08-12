terraform {
  backend "s3" {
    bucket       = "aws-cloud-infra-prod-c3cf66f6e6"
    key          = "aws-cloud-infra/prod/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 5
}


resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_name}-${var.environment}-${random_id.bucket_suffix.hex}"
  lifecycle {
    prevent_destroy = true
  }
  tags = merge(local.default_tags, {
    Use = "terraform-state-backend"
  })
}


resource "aws_s3_bucket_versioning" "terraform_state" {
  count  = var.enable_bucket_versioning ? 1 : 0
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_ownership_controls" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket     = aws_s3_bucket.terraform_state.id
  depends_on = [aws_s3_bucket_versioning.terraform_state]
  rule {
    id = "terraform_state_lifecycle"
    filter {
      prefix = local.state_path
    }
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = var.state_version_retention_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# IAM policy for Terraform state access
resource "aws_iam_policy" "terraform_state_policy" {
  name        = "${var.project_name}-terraform-state-policy-${var.environment}"
  description = "Policy for Terraform state bucket access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketVersioning"
        ]
        Resource = aws_s3_bucket.terraform_state.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.terraform_state.arn}/*"
      },
    ]
  })
}
