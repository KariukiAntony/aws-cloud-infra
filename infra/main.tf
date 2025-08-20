provider "aws" {
  region = var.region
}

locals {
  state_path = "${var.project_name}/${var.environment}"
  default_tags = {
    Project        = "${var.project_name}"
    Environment = "${var.environment}"
    ManagedBy   = "Terraform"
  }
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

  tags = local.default_tags
}