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
module "storage" {
  source = "./modules/storage"

  enable_bucket_versioning           = var.enable_frontend_bucket_versioning
  noncurrent_version_expiration_days = var.noncurrent_version_expiration_days

  base_name = local.base_name
  tags      = local.default_tags
}

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

  frontend_bucket_id  = module.storage.bucket_id
  frontend_bucket_arn = module.storage.bucket_arn

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

  ami_id             = data.aws_ami.latest_ubuntu.id
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnets_ids
  private_subnet_ids = module.networking.private_subnets_ids

  alb_security_group_id = module.security.alb_security_group_id
  ec2_cloudwatch_role   = module.security.ec2_cloudwatch_role

  enable_alb_deletion_protection = false
  ssl_certificate_arn            = module.dns-ssl.alb_certificate_arn

  instance_type            = var.instance_type
  key_name                 = module.security.key_pair
  security_group_id        = module.security.private_security_group_id
  enable_monitoring        = var.enable_monitoring
  template_data_script     = "${path.root}/../${var.template_data_script}"
  ec2_cloudwatch_log_group = var.ec2_cloudwatch_log_group

  min_size           = var.min_size
  max_size           = var.max_size
  desired_capacity   = var.desired_capacity
  scaling_adjustment = var.scaling_adjustment

  base_name = local.base_name
  tags      = local.default_tags
}

module "dns-ssl" {
  source      = "./modules/dns-ssl"
  domain_name = var.domain_name

  base_name = local.base_name
  tags      = local.default_tags
}

module "cdn" {
  source = "./modules/cdn"

  enabled         = var.enabled
  is_ipv6_enabled = var.is_ipv6_enabled
  comment         = var.comment
  price_class     = var.price_class

  default_root_object     = var.default_root_object
  custom_error_page_path  = var.custom_error_page_path
  s3_regional_domain_name = module.storage.bucket_regional_domain
  allowed_methods         = var.allowed_methods
  cached_methods          = var.cached_methods
  web_acl_id              = var.web_acl_id
  compress                = var.compress
  min_ttl                 = var.min_ttl
  default_ttl             = var.default_ttl
  max_ttl                 = var.max_ttl

  ssl_support_method     = var.ssl_support_method
  origin_protocol_policy = var.origin_protocol_policy
  s3_bucket_prefix       = var.s3_bucket_prefix
  wait_for_deployment    = var.wait_for_deployment

  viewer_protocol_policy   = var.viewer_protocol_policy
  minimum_protocol_version = var.minimum_protocol_version
  aliases                  = [var.domain_name, "www.${var.domain_name}"]
  acm_certificate_arn      = module.dns-ssl.cloudfront_certificate_arn

  base_name = local.base_name
  tags      = local.default_tags
}

module "monitoring" {
  source = "./modules/monitoring"

  high_cpu_threshold     = var.high_cpu_threshold
  high_memory_threshold  = var.high_memory_threshold
  notification_email     = var.notification_email
  scale_up_policy_arn    = module.compute.scale_up_policy_arn
  scale_down_policy_arn  = module.compute.scale_down_policy_arn
  autoscaling_group_name = module.compute.autoscaling_group_name

  instance_type = var.instance_type

  base_name = local.base_name
  tags      = local.default_tags
}

# Type A DNS records to CloudFront
resource "aws_route53_record" "root_domain" {
  name    = var.domain_name
  zone_id = module.dns-ssl.zone_id
  type    = "A"
  alias {
    name                   = module.cdn.cloudfront_domain_name
    zone_id                = module.cdn.cloudfront_hosted_zone_id
    evaluate_target_health = true
  }
}

# WWW subdomain pointing to CloudFront.
resource "aws_route53_record" "www" {
  name    = "www.${var.domain_name}"
  zone_id = module.dns-ssl.zone_id
  type    = "A"

  alias {
    name                   = module.cdn.cloudfront_domain_name
    zone_id                = module.cdn.cloudfront_hosted_zone_id
    evaluate_target_health = true
  }
}

# Type A DNS records the ALB
resource "aws_route53_record" "api_domain" {
  name    = "api.${var.domain_name}"
  zone_id = module.dns-ssl.zone_id
  type    = "A"
  alias {
    name                   = module.compute.alb_dns_hostname
    zone_id                = module.compute.alb_zoneid
    evaluate_target_health = true
  }
}