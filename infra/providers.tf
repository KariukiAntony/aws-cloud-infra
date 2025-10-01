terraform {
  required_version = ">=1.10"
  required_providers {

    aws = {
      source  = "hashicorp/aws"
      version = "6.0.0" # Exact version due to workflows.
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.7.0"
    }
  }
}

