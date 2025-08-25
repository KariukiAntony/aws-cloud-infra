output "zone_id" {
  description = "Hosted zone ID"
  value       = data.aws_route53_zone.main.zone_id
}

output "cloudfront_certificate_arn" {
  description = "ARN of the cloudFront certificate "
  value       = aws_acm_certificate.cloudfront_cert.arn
}

output "alb_certificate_arn" {
  description = "ARN of the ALB certificate "
  value       = aws_acm_certificate.alb_cert.arn
}