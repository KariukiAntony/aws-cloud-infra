variable "domain_name" {
  description = "The domain name of your application"
  type        = string
}

variable "base_name" {
  description = "Basename for all resources"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {}
}