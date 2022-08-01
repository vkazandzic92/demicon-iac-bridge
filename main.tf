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