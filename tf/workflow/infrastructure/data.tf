data "aws_caller_identity" "current" {}

data "terraform_remote_state" "iam" {
  backend = "s3"

  config = {
    region     = "eu-west-1"
    bucket     = "data-tf-backend"
    key        = "cognism/aws/environments/data-dev/science/demo_strands_agent/workflow/iam/terraform.tfstate"
    encrypt    = true
    kms_key_id = "arn:aws:kms:eu-west-1:514595551765:key/78f573d5-804c-4c04-9a30-810f853e62c7"
    profile    = "cognism-data-mlops-dev"
  }
}
