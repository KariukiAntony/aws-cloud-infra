variable "ami_id" {
  description = "AMI ID for instances"
  type        = string
}

variable "instance_type" {
  description = "Instance type for your application servers"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the vpc"
  type        = string
}

variable "key_name" {
  description = "Instance key-pair"
  type        = string
}

variable "security_group_id" {
  description = "Instance security group ID"
  type        = string
}

variable "base_name" {
  description = "The basename for all resources"
  type        = string
}

variable "alb_security_group_id" {
  description = "ALB security group ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "enable_alb_deletion_protection" {
  description = "Disable the deletion of load balancer via AWS API"
  type        = bool
}

variable "ssl_certificate_arn" {
  description = "ARN of the ACM issued certificate"
  type        = string
}

variable "ec2_cloudwatch_role" {
  description = "EC2 role to enable CloudWatch Agents to publish metrics to CloudWatch"
  type        = string
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
}

variable "template_data_script" {
  description = "Path to template data script"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
