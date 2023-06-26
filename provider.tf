# provider.tf - Defines the AWS provider and the version of the provider to use.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
