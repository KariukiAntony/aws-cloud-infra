provider "aws" {
  region = var.region
}

locals {
  state_path = "${var.project_name}/${var.environment}"
  default_tags = {
    Project     = "${var.project_name}"
    Environment = "${var.environment}"
    ManagedBy   = "Terraform"
  }
  base_name = "${var.project_name}-${var.environment}"
}

# ---- Modules ----
module "networking" {
  source = "./modules/networking"

  vpc_cidr                = var.vpc_cidr
  enable_vpc_dns_hostname = var.enable_vpc_dns_hostname
  enable_vpc_dns_support  = var.enable_vpc_dns_support

  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway

  base_name = local.base_name
  tags      = local.default_tags
}

module "security" {
  source = "./modules/security"

  vpc_id                           = module.networking.vpc_id
  bastion_host_key_path            = var.bastion_host_key_path
  bastion_host_allowed_cidr_blocks = var.bastion_host_allowed_cidr_blocks
  allow_bastion_host_http_traffic  = var.allow_bastion_host_http_traffic
  allow_bastion_host_https_traffic = var.allow_bastion_host_https_traffic


  private_instance_key_path = var.private_instance_key_path
  base_name                 = local.base_name
  tags                      = local.default_tags
}