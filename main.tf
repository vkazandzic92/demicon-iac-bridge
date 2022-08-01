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

provider "archive" {}

data "archive_file" "zip" {
  type        = "zip"
  source_file = "lambda_functions/terraform_state_lambda.py"
  output_path = "lambda_functions/terraform_state_lambda.zip"
}

# Lambda Assume role
data "aws_iam_policy_document" "assume_role" {
  statement {
    sid    = ""
    effect = "Allow"

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

# S3 Get object lambda role
resource "aws_iam_policy" "lambda_s3" {
  policy = data.aws_iam_policy_document.lambda_s3_access_document.json
}

# Lambda assume role and s3 get object role
resource "aws_iam_role_policy_attachment" "s3" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_s3.arn
}

# Lambda assume role
resource "aws_iam_role" "iam_for_lambda" {
  name               = "S3GetObjectLambdaAssumeRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# S3 policy get object access
data "aws_iam_policy_document" "lambda_s3_access_document" {
  statement {
    sid = "1"
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "arn:aws:s3:::demicon-terraform-state/*",
    ]
  }
}
resource "aws_lambda_function" "lambda" {
  function_name = "terraform_state_lambda"

  filename         = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256

  role    = aws_iam_role.iam_for_lambda.arn
  handler = "terraform_state_lambda.lambda_handler"
  runtime = "python3.8"

  environment {
    variables = {
      object_key = var.terraform_bucket_key
      bucket     = var.terraform_bucket_name
    }
  }
}
resource "null_resource" "install_python_dependencies" {
  provisioner "local-exec" {
    command = "pip install -r lambda_functions/requirements.txt"
  }
}

resource "aws_alb" "demicon" {
  name               = "demicon-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.Demicon_VPC_Security_Group.id]
  subnets            = [aws_subnet.Demicon_VPC_Subnet-1a.id, aws_subnet.Demicon_VPC_Subnet-1b.id]
}

# create the VPC
resource "aws_vpc" "Demicon_VPC" {
  cidr_block           = var.vpc_CIDR_block
  instance_tenancy     = var.instance_tenancy
  enable_dns_support   = var.dns_support
  enable_dns_hostnames = var.dns_host_names
  tags = {
    Name = "Demicon VPC"
  }
} # end resource
# create the Subnet
resource "aws_subnet" "Demicon_VPC_Subnet-1a" {
  vpc_id                  = aws_vpc.Demicon_VPC.id
  cidr_block              = var.subnet_CIDR_block_1a
  map_public_ip_on_launch = var.map_public_ip
  availability_zone       = var.availability-zone-1a
  tags = {
    Name = "Demicon VPC Subnet"
  }
}
resource "aws_subnet" "Demicon_VPC_Subnet-1b" {
  vpc_id                  = aws_vpc.Demicon_VPC.id
  cidr_block              = var.subnet_CIDR_block_1b
  map_public_ip_on_launch = var.map_public_ip
  availability_zone       = var.availability_zone-1b
  tags = {
    Name = "Demicon VPC Subnet 1 b"
  }
}

# Create the Security Group
resource "aws_security_group" "Demicon_VPC_Security_Group" {
  vpc_id      = aws_vpc.Demicon_VPC.id
  name        = "Demicon VPC Security Group"
  description = "Demicon VPC Security Group"

  # allow ingress of port 22
  ingress {
    cidr_blocks = var.ingress_CIDR_block
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }

  # allow egress of all ports
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.egress_CIDR_block
  }
  tags = {
    Name        = "Demicon VPC Security Group"
    Description = "Demicon VPC Security Group"
  }
}
# create VPC Network access control list
resource "aws_network_acl" "Demicon_VPC_Security_ACL" {
  vpc_id     = aws_vpc.Demicon_VPC.id
  subnet_ids = [aws_subnet.Demicon_VPC_Subnet-1a.id, aws_subnet.Demicon_VPC_Subnet-1b.id]
  # allow ingress port 22
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.destination_CIDR_block
    from_port  = 22
    to_port    = 22
  }

  # allow ingress port 80 
  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = var.destination_CIDR_block
    from_port  = 80
    to_port    = 80
  }

  # allow ingress ephemeral ports 
  ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = var.destination_CIDR_block
    from_port  = 1024
    to_port    = 65535
  }

  # allow egress port 22 
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.destination_CIDR_block
    from_port  = 22
    to_port    = 22
  }

  # allow egress port 80 
  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = var.destination_CIDR_block
    from_port  = 80
    to_port    = 80
  }

  # allow egress ephemeral ports
  egress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = var.destination_CIDR_block
    from_port  = 1024
    to_port    = 65535
  }
  tags = {
    Name = "Demicon VPC ACL"
  }
}
# Create the Internet Gateway
resource "aws_internet_gateway" "Demicon_VPC_GW" {
  vpc_id = aws_vpc.Demicon_VPC.id
  tags = {
    Name = "Demicon VPC Internet Gateway"
  }
}
# Create the Route Table
resource "aws_route_table" "Demicon_VPC_route_table" {
  vpc_id = aws_vpc.Demicon_VPC.id
  tags = {
    Name = "Demicon VPC Route Table"
  }
}
# Create the Internet Access
resource "aws_route" "Demicon_VPC_internet_access" {
  route_table_id         = aws_route_table.Demicon_VPC_route_table.id
  destination_cidr_block = var.destination_CIDR_block
  gateway_id             = aws_internet_gateway.Demicon_VPC_GW.id
}
# Associate the Route Table with the Subnet
resource "aws_route_table_association" "Demicon_VPC_association-1-a" {
  subnet_id      = aws_subnet.Demicon_VPC_Subnet-1a.id
  route_table_id = aws_route_table.Demicon_VPC_route_table.id
}

# Associate the Route Table with the Subnet
resource "aws_route_table_association" "Demicon_VPC_association_1-b" {
  subnet_id      = aws_subnet.Demicon_VPC_Subnet-1b.id
  route_table_id = aws_route_table.Demicon_VPC_route_table.id
}


resource "aws_alb_target_group" "demicon_alb_tg" {
  name     = "tf-demicon-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.Demicon_VPC.id
}
resource "aws_alb_listener" "demicon_alb" {
  load_balancer_arn = aws_alb.demicon.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.demicon_alb_tg.arn
  }
}

resource "aws_alb_listener_certificate" "cert" {
  listener_arn    = aws_alb_listener.demicon_alb.arn
  certificate_arn = aws_acm_certificate.cert.arn
}

resource "tls_private_key" "pk" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "example" {

  private_key_pem = tls_private_key.pk.private_key_pem

  subject {
    common_name  = "example.com"
    organization = "ACME Examples, Inc"
  }

  validity_period_hours = 24

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "cert" {
  private_key      = tls_private_key.pk.private_key_pem
  certificate_body = tls_self_signed_cert.example.cert_pem
}

# TODO: needed EC2 instances to expose the URL
