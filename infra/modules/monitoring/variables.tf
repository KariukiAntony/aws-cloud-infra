variable "base_name" {
  description = "The basename for all resources"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
}

variable "notification_email" {
  description = "Email to get notifications"
  type        = string
}

variable "scale_up_policy_arn" {
  description = "Scale up policy ARN"
  type        = string
}

variable "scale_down_policy_arn" {
  description = "Scale down policy ARN"
  type        = string
}

variable "autoscaling_group_name" {
  description = "Name of the autoscaling group"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the Auto Scaling Group"
  type        = string
  validation {
    condition     = can(regex("^[a-z][0-9]+[a-z]*\\.", var.instance_type))
    error_message = "Instance type must be a valid EC2 instance type format (e.g., t3.micro, m5.large)."
  }
}

variable "high_cpu_threshold" {
  description = "The maximum cpu threshold to trigger auto scaling"
  type        = number
}

variable "high_memory_threshold" {
  description = "The maximum memory threshold to trigger auto scaling"
  type        = number
}