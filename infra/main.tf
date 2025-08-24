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

# ---- Shared data sources across the modules ----

# Latest ubuntu AMI
data "aws_ami" "latest_ubuntu" {
  owners      = ["099720109477"] # Canonical's AWS Account ID for Ubuntu AMIs
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
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

  base_name = local.base_name
  tags      = local.default_tags
}

module "security" {
  source = "./modules/security"

  vpc_id                           = module.networking.vpc_id
  host_key_path                    = var.host_key_path
  bastion_host_allowed_cidr_blocks = var.bastion_host_allowed_cidr_blocks
  allow_bastion_host_http_traffic  = var.allow_bastion_host_http_traffic
  allow_bastion_host_https_traffic = var.allow_bastion_host_https_traffic

  base_name = local.base_name
  tags      = local.default_tags
}

module "bastion" {
  source                    = "./modules/bastion"
  ami_id                    = data.aws_ami.latest_ubuntu.id
  bastion_instance_type     = var.bastion_instance_type
  public_subnet_ids         = module.networking.public_subnets_ids
  bastion_security_group_id = module.security.bastion_security_group_id
  key_pair                  = module.security.key_pair
  bastion_user_data_script  = "${path.root}/../${var.bastion_data_script_path}"

  base_name = local.base_name
  tags      = local.default_tags
}

module "compute" {
  source = "./modules/compute"

  ami_id            = data.aws_ami.latest_ubuntu.id
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnets_ids

  alb_security_group_id = module.security.alb_security_group_id
  ec2_cloudwatch_role   = module.security.ec2_cloudwatch_role

  enable_alb_deletion_protection = false
  ssl_certificate_arn            = "arn:aws:acm:eu-central-1:618480996469:certificate/595fe24f-d30f-442c-9552-69de72ea6a14"

  instance_type        = var.instance_type
  key_name             = module.security.key_pair
  security_group_id    = module.security.private_security_group_id
  enable_monitoring    = var.enable_monitoring
  template_data_script = "${path.root}/../${var.template_data_script}"

  base_name = local.base_name
  tags      = local.default_tags
}