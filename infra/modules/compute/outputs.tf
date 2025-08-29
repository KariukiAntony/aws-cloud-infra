
output "alb_dns_hostname" {
  description = "DNS hostname for the ALB"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN for the ALB"
  value       = aws_lb.main.arn
}

output "alb_zoneid" {
  description = "Zone ID for ALB"
  value       = aws_lb.main.zone_id
}

output "scale_up_policy_arn" {
  description = "ARN of the scale up policy"
  value       = aws_autoscaling_policy.scale_up.arn
}

output "scale_down_policy_arn" {
  description = "ARN of the scale down policy"
  value       = aws_autoscaling_policy.scale_down.arn
}

output "autoscaling_group_name" {
  description = "Name of ASG"
  value       = aws_autoscaling_group.main.name
}