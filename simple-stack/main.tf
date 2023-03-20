# Bucket need to be created manually
terraform {
  required_version = ">= 1.3.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    encrypt = true
    bucket  = "tf-poc-simple-stack-state"
    region  = "eu-central-1"
    key     = "simple-stack-dev"
    profile = "aws-poc-profile"
  }
}

provider "aws" {
  region  = "eu-central-1"
  profile = "aws-poc-profile"
}

