# ----- VPC -----

variable "vpc_cidr" {
  type = string
}

variable "enable_vpc_dns_support" {
  type = bool
}

variable "enable_vpc_dns_hostname" {
  type = bool
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "enable_nat_gateway" {
  type    = bool
  default = true
}

variable "base_name" {
  type = string
}

variable "tags" {
  type = map(string)
}
