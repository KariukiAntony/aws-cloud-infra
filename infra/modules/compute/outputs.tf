output "bastion_public_ip" {
  description = "IPv4 address of the bastion host"
  value       = aws_instance.bastion.public_ip
}

output "bastion_public_dns" {
  description = "Public dns of the bastion host"
  value       = aws_instance.bastion.public_dns
}