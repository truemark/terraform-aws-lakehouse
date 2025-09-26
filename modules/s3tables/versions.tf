terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.10.0" # S3 Tables resources are in v6+
    }
  }
}