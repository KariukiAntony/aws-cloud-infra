# --- Root module ---
region                   = "eu-central-1"
project_name             = "aws-cloud-infra"
environment              = "prod"
enable_bucket_versioning = false

# --- Networking module ---
vpc_cidr                = "10.0.0.0/16"
enable_vpc_dns_support  = true
enable_vpc_dns_hostname = true
public_subnet_cidrs     = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs    = ["10.0.11.0/24", "10.0.12.0/24"]
enable_nat_gateway      = true

# --- Security Module ---
host_key_path                    = "~/.ssh/id_rsa.pub"
bastion_host_allowed_cidr_blocks = ["0.0.0.0/0"]
allow_bastion_host_http_traffic  = true
allow_bastion_host_https_traffic = true

# --- Compute ---
instance_type                  = "t3.micro"
enable_alb_deletion_protection = false
enable_monitoring              = true
template_data_script           = "scripts/template_data.sh"
min_size                       = 1
max_size                       = 2
desired_capacity               = 1
scaling_adjustment             = 1
enable_https = true


# --- Bastion ---
bastion_instance_type    = "t2.micro"
bastion_data_script_path = "scripts/bastion_data.sh"

# ---- dns-ssl ----
domain_name = "citybandit.tech"

# ---- monitoring ----
ec2_cloudwatch_log_group = "ec2_log_group"
high_cpu_threshold       = 50
high_memory_threshold    = 50
notification_email       = "antonygichoya9@gmail.com"

# ---- cdn ----
enabled                  = true
is_ipv6_enabled          = true
default_root_object      = "/index.html"
custom_error_page_path   = "/error.html"
price_class              = "PriceClass_All"
allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
cached_methods           = ["GET", "HEAD"]
s3_bucket_prefix         = "cloudfront-logs/"
wait_for_deployment      = false
min_ttl                  = 0
default_ttl              = 3600
max_ttl                  = 8600
compress                 = true
viewer_protocol_policy   = "redirect-to-https"
minimum_protocol_version = "TLSv1.2_2021"
origin_protocol_policy   = "https-only"