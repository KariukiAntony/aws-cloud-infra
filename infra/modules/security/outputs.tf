output "bastion_security_group_id" {
  description = "Bastion host security group ID"
  value       = aws_security_group.bastion.id
}

output "key_pair" {
  description = "Bastion host key name"
  value       = aws_key_pair.key.key_name
}

output "private_security_group_id" {
  description = "Private instance security group ID"
  value       = aws_security_group.private.id
}


output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

# --- Roles and Policies
output "ec2_cloudwatch_role" {
  description = "EC2 role to enable CloudWatch Agents to publish metrics to CloudWatch"
  value       = aws_iam_role.ec2_cloudwatch.name
}