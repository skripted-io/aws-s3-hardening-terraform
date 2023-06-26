# lambda.tf - Provisions a Lambda function to test our setup

# Congiruate a security group for the Lambda function
resource "aws_security_group" "service_lambda_sg" {
  vpc_id      = var.vpc_id
  name        = "${var.service_name}-service-lambda-sg"
  description = "Lambda SG for ${var.service_name}-${var.environment}"

  tags = {
    Service     = var.service_name
    Environment = var.environment
    Name        = "${var.service_name}"
    Terraform   = "true"
  }
}

# Allow outbound traffic so the Lambda can access the S3 endpoint
resource "aws_security_group_rule" "allow_egress" {
  description       = "Allows Lambda egress"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.service_lambda_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# Define a role trust policy so Lambda can assume a role
data "aws_iam_policy_document" "service_lambda_role_trust_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Provision the IAM role for the Lambda function
resource "aws_iam_role" "service_lambda_execution_role" {
  name               = "${var.service_name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.service_lambda_role_trust_policy.json

  tags = {
    Service     = var.service_name
    Environment = var.environment
    Name        = "${var.service_name}-lambda-role"
    Terraform   = "true"
  }
}

# Attach "AWSLambdaBasicExecutionRole" managed policy so Lambda can write logs to CloudWatch
resource "aws_iam_role_policy_attachment" "service_lambda_role_basic_policy" {
  role       = aws_iam_role.service_lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach "AWSLambdaVPCAccessExecutionRole" managed policy so Lambda can access resources in the VPC
resource "aws_iam_role_policy_attachment" "translate_service_lambda_role_vpc_access_policy" {
  role       = aws_iam_role.service_lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Define a custom IAM Policy for the Lambda to access the S3 bucket
data "aws_iam_policy_document" "s3_access_policy_document" {
  statement {
    actions   = ["s3:putObject", "s3:getObject"]
    resources = ["${aws_s3_bucket.bucket.arn}/*"]
  }
}

# Attach the custom IAM Policy for the Lambda to access the S3 bucket
resource "aws_iam_role_policy" "lambda_s3_access_policy" {
  name   = "iam_for_lambda_policy"
  role   = aws_iam_role.service_lambda_execution_role.id
  policy = data.aws_iam_policy_document.s3_access_policy_document.json
}

# Define the location of the Lambda function source code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "./lambda_source/lambda_function.py"
  output_path = "./lambda_source/lambda_function_py_source.zip"
}

# Provision the Lambda function
resource "aws_lambda_function" "lambda_function" {
  function_name    = "${var.service_name}-function"
  filename         = data.archive_file.lambda_zip.output_path
  role             = aws_iam_role.service_lambda_execution_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.9"

  vpc_config {
    subnet_ids         = var.private_subnet_ids # Launch our Lambda function into the private subnets
    security_group_ids = [aws_security_group.service_lambda_sg.id]
  }

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.bucket.bucket # Needed for the python code to find the bucket
    }
  }

  tags = {
    "Service"     = var.service_name
    "Environment" = var.environment
    "Name"        = "${var.service_name}-service-lambda-function"
    "Terraform"   = "true"
  }
}
