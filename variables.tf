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

variable "availability-zone-1a" {
  default = "eu-central-1a"
}
variable "availability_zone-1b" {
  default = "eu-central-1b"
}
variable "instance_tenancy" {
  default = "default"
}
variable "dns_support" {
  default = true
}
variable "dns_host_names" {
  default = true
}
variable "vpc_CIDR_block" {
  default = "10.0.0.0/16"
}
variable "subnet_CIDR_block_1a" {
  default = "10.0.1.0/24"
}
variable "subnet_CIDR_block_1b" {
  default = "10.0.0.0/24"
}
variable "destination_CIDR_block" {
  default = "0.0.0.0/0"
}
variable "ingress_CIDR_block" {
  type    = list(any)
  default = ["0.0.0.0/0"]
}
variable "egress_CIDR_block" {
  type    = list(any)
  default = ["0.0.0.0/0"]
}
variable "map_public_ip" {
  default = true
}
