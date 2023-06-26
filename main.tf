# main.tf - Creates a VPC endpoint for S3 that our Lambda will use.

# Endpoint policy for the S3 endpoint
data "aws_iam_policy_document" "s3_endpoint_policy" {
  statement {
    actions   = ["s3:putObject", "s3:getObject"]
    resources = ["${aws_s3_bucket.bucket.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:PrincipalArn"
      values   = [aws_iam_role.service_lambda_execution_role.arn] # only allow access to this endpoint from the Lambda function
    }
  }
}

# VPC gateway endpoint for S3. This will make sure our Lambda can access S3 without going over the internet
resource "aws_vpc_endpoint" "s3_vpce" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.private_rt_ids
  policy            = data.aws_iam_policy_document.s3_endpoint_policy.json

  tags = {
    Service     = var.service_name
    Name        = "${var.service_name}-${var.environment}-s3-vpce"
    Environment = var.environment
    Terraform   = "true"
  }
}
