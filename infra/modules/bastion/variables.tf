variable "ami_id" {
  description = "The AMI ID for bastion host"
  type        = string
}

variable "bastion_instance_type" {
  description = "The instance type of the bastion host"
  type        = string
}

variable "public_subnet_ids" {
  description = "The IDs of public subnets"
  type        = list(string)
  validation {
    condition     = length(var.public_subnet_ids) > 0
    error_message = "At least one public subnet ID must be provided"
  }
}

variable "bastion_security_group_id" {
  description = "Bastion host security group"
  type        = string
}

variable "key_pair" {
  description = "Bastion key-pair"
  type        = string
}


variable "bastion_user_data_script" {
  description = "Path to the user data script"
  type        = string
  default     = ""
  validation {
    condition     = fileexists(var.bastion_user_data_script) || var.bastion_user_data_script == ""
    error_message = "Bastion user data script file does not exists in the specified location."
  }
}



variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {}
}

variable "base_name" {
  description = "The basename for all resources."
}