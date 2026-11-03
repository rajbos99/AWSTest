terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Provider for Account A (Account ID: 000000000000)
provider "aws" {
  alias  = "account_a"
  region = var.aws_region
}

# Provider for Account B (Account ID: 111111111111)
provider "aws" {
  alias  = "account_b"
  region = var.aws_region
}

