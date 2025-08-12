provider "aws" {
  region = var.region
}

locals {
  state_path = "${var.project_name}/${var.environment}/"
  default_tags = {
    Name        = "${var.project_name}"
    Environment = "${var.environment}"
    ManagedBy   = "Terraform"
  }
}