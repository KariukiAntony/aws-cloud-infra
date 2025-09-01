output "bucket_arn" {
  description = "ARN of the frontend bucket"
  value       = aws_s3_bucket.frontend.arn
}

output "bucket_id" {
  description = "ID of the frontend bucket"
  value       = aws_s3_bucket.frontend.id
}

output "bucket_regional_domain" {
  description = "Bucket region-specific domain name"
  value       = aws_s3_bucket.frontend.bucket_regional_domain_name
}