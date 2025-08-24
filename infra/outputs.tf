# --- Root module ----
output "bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

output "iam_policy_arn" {
  description = "ARN of the IAM policy for Terraform state access"
  value       = aws_iam_policy.terraform_state_policy.arn
}

# --- Networking module ----

# --- Security module ---

# --- Bastion module ---
output "bastion_commands" {
  description = "Commands to connect to bastion host"
  value = {
    public_ip   = module.bastion.bastion_public_ip
    public_dns  = module.bastion.bastion_public_dns
    ssh_command = "ssh ubuntu@${module.bastion.bastion_public_ip}"
  }
}

# --- Compute module ---