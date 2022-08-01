variable "aws_region" {
  default = "eu-central-1"
}

variable "aws_profile" {
  default = "default"
}

variable "aws_shared_credentials_file" {
  default   = "aws_cred/cred"
  sensitive = true
}

variable "aws_shared_config_file" {
  default   = "aws_cred/conf"
  sensitive = true
}

variable "terraform_bucket_name" {
  default = "demicon-terraform-state"
}

variable "terraform_bucket_key" {
  default = "terraform.tfstate"
}
