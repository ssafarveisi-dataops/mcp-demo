terraform {
  required_version = "~> 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.36"
    }
  }

  backend "s3" {
    region       = "eu-west-1"
    bucket       = "data-tf-backend"
    use_lockfile = true
    encrypt      = true
    kms_key_id   = "arn:aws:kms:eu-west-1:514595551765:key/78f573d5-804c-4c04-9a30-810f853e62c7"
    key          = "cognism/aws/environments/data-dev/science/demo_strands_agent/workflow/infrastructure/terraform.tfstate"
    profile      = "cognism-data-mlops-dev"
  }
}

provider "aws" {
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "cognism-data-mlops-dev"
  region                   = var.aws_region
}
