# s3.tf - Provisions an S3 bucket 

# Generate a random name to add to our bucket name
resource "random_pet" "bucket_name" {
  length    = 2
  separator = "-"
}

# Provision the S3 bucket
resource "aws_s3_bucket" "bucket" {
  bucket = "${var.service_name}-${random_pet.bucket_name.id}"

  tags = {
    Service     = var.service_name
    Environment = var.environment
    Name        = "${var.service_name}-${var.environment}-s3-bucket"
    Terraform   = "true"
  }
}

# Configure S3 bucket ownership controls
resource "aws_s3_bucket_ownership_controls" "bucket_ownership" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Configure S3 server side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "sse_config" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.kms_key.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true # The bucket key reduces encryption costs by lowering calls to AWS KMS.
  }
}

# Define an S3 bucket policy that only allows access from the VPC S3 Gateway endpoint
data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid    = "DenyAllUnlessFromSpecificVPCe" # deny everybody not coming in via the VPC endpoint
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["${aws_iam_role.service_lambda_execution_role.arn}"]
    }

    actions = ["s3:*"]

    resources = [
      "${aws_s3_bucket.bucket.arn}/*", # allow access to all objects in the bucket
      # "${aws_s3_bucket.bucket.arn}" # optional: allow access to the bucket itself
    ]

    condition {
      test     = "StringNotEquals"
      variable = "aws:sourceVpce"
      values = [
        aws_vpc_endpoint.s3_vpce.id # only allow access when the workload account is using this VPC S3 Gateway endpoint
      ]
    }
  }
}

# Attach the S3 bucket policy to the S3 bucket
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}
