locals {
  key_policy_admins = [
    # Account Root
    "arn:aws:iam::${data.aws_caller_identity.this.account_id}:root",

    # Me. Now.  For testing. Remove
    data.aws_caller_identity.this.arn

    # In practice / production, this should be a small list. A Security account plus
    # break-glass.
  ]
}

data "aws_caller_identity" "this" {}

data "aws_region" "current" {}

# Key for CloudWatch Logs / VPC Flow Logs / (optionally) CloudTrail in this account
resource "aws_kms_key" "log" {
  description             = "Account log key (CloudWatch Logs, VPC Flow Logs, etc.)"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Key admin in this account
      {
        Sid       = "KeyAdmin"
        Effect    = "Allow"
        Principal = { AWS = local.key_policy_admins }
        Action    = "kms:*"
        Resource  = "*"
      },
      # Log services in this account (CloudWatch Logs, VPC Flow Logs) - narrow as needed
      {
        Sid    = "AllowLogsUse"
        Effect = "Allow"
        Principal = {
          Service = [
            "logs.${data.aws_region.current.id}.amazonaws.com",
            "vpc-flow-logs.amazonaws.com"
          ]
        }
        Action = [
          "kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

# Default CMK for EBS encryption
resource "aws_kms_key" "ebs_default" {
  description             = "Default EBS CMK for this account/region"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = aws_kms_key.log.policy
}

# Optional data CMK for app data services (RDS, app S3, OpenSearch, DynamoDB streams, etc.)
resource "aws_kms_key" "data" {
  count                   = var.enable_optional_data_kms ? 1 : 0
  description             = "Data CMK for application storage (use per-service policies on resources)"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = aws_kms_key.log.policy
}
