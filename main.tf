terraform {
  required_version = ">= 0.12"

  backend "s3" {
    bucket                  = "demicon-terraform-state"
    key                     = "terraform.tfstate"
    region                  = "eu-central-1"
    shared_credentials_file = "aws_cred/cred"
    profile                 = "default"
    encrypt                 = true
  }
}

provider "aws" {
  region                   = var.aws_region
  shared_config_files      = [var.aws_shared_config_file]
  shared_credentials_files = [var.aws_shared_credentials_file]
  profile                  = var.aws_profile
}