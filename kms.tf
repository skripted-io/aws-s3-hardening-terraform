# kms.tf - Provisions a KMS key for the S3 bucket and Lambda to use

# Define an account specific data source
data "aws_caller_identity" "current" {}

# Provision the KMS key
resource "aws_kms_key" "kms_key" {
  description             = "KMS key for ${var.service_name} in the ${var.environment} environment"
  deletion_window_in_days = 7

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "${var.service_name}-${var.environment}-key-policy",
    Statement = concat([
      {
        Sid    = "Allow administration of the key",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" # allow the root user to administer the key but not use it
        },
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ],
        Resource = "*"
      },
      {
        Sid    = "Allow use of the key",
        Effect = "Allow",
        Principal = {
          AWS = "${aws_iam_role.service_lambda_execution_role.arn}" # allow the lambda execution role to use the key but not administer it
        },
        Action   = ["kms:Decrypt", "kms:DescribeKey", "kms:Encrypt", "kms:GenerateDataKey*", "kms:ReEncrypt*", "kms:CreateGrant"]
        Resource = "*"
      }]
    )
  })

  tags = {
    Service     = var.service_name
    Environment = var.environment
    Name        = "${var.service_name}-kms-key"
    Terraform   = "true"
  }
}

# Add an alias to the KMS key
resource "aws_kms_alias" "kms_alias" {
  name          = "alias/${var.service_name}-kms-key" # add an alias for easier identification in the console
  target_key_id = aws_kms_key.kms_key.key_id
}
