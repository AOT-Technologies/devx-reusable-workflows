terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" 
    }
  }
}

# Provider configuration
provider "aws" {
  region = var.aws_region
}

# Special Provider for CloudFront Certs (Must be us-east-1)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}