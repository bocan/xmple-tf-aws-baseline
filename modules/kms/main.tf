############################################
# Data: who am I (account id is used in KMS policies)
############################################
data "aws_caller_identity" "this" {}

############################################
# Logs CMK: for CloudWatch Logs encryption
############################################
resource "aws_kms_key" "logs" {
  description             = "App account: CMK for CloudWatch Logs encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  # Explicit policy to satisfy CKV2_AWS_64 and constrain usage to CW Logs in THIS account
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      # Admin in this account
      {
        Sid : "EnableRootAdmin",
        Effect : "Allow",
        Principal : { AWS : "arn:aws:iam::${data.aws_caller_identity.this.account_id}:root" },
        Action : "kms:*",
        Resource : "*"
      },
      # Allow CloudWatch Logs to use the key via the service in this account
      {
        Sid : "AllowCloudWatchLogsViaService",
        Effect : "Allow",
        Principal : "*",
        Action : [
          "kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*",
          "kms:GenerateDataKey*", "kms:DescribeKey"
        ],
        Resource : "*",
        Condition : {
          "StringLike" : { "kms:ViaService" : "logs.*.amazonaws.com" },
          "StringEquals" : { "aws:SourceAccount" : data.aws_caller_identity.this.account_id }
        }
      }
    ]
  })
}

resource "aws_kms_alias" "logs" {
  name          = "alias/${var.alias_prefix}-logs"
  target_key_id = aws_kms_key.logs.key_id
}

############################################
# EBS Default CMK: used as the account default for EBS encryption
############################################
resource "aws_kms_key" "ebs" {
  description             = "App account: CMK for default EBS encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  # Explicit policy: allow EC2/EBS to use the key via the service in this account
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Sid : "EnableRootAdmin",
        Effect : "Allow",
        Principal : { AWS : "arn:aws:iam::${data.aws_caller_identity.this.account_id}:root" },
        Action : "kms:*",
        Resource : "*"
      },
      {
        Sid : "AllowEC2EBSViaService",
        Effect : "Allow",
        Principal : "*",
        Action : [
          "kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*",
          "kms:GenerateDataKey*", "kms:DescribeKey"
        ],
        Resource : "*",
        Condition : {
          "StringLike" : { "kms:ViaService" : "ec2.*.amazonaws.com" },
          "StringEquals" : { "aws:SourceAccount" : data.aws_caller_identity.this.account_id }
        }
      }
    ]
  })
}

resource "aws_kms_alias" "ebs" {
  name          = "alias/${var.alias_prefix}-ebs-default"
  target_key_id = aws_kms_key.ebs.key_id
}

# Turn on EBS encryption-by-default and set the CMK
resource "aws_ebs_encryption_by_default" "on" {
  enabled = true
}

resource "aws_ebs_default_kms_key" "default" {
  key_arn = aws_kms_key.ebs.arn
}

############################################
# Optional Data CMK: for common service-integrated encryption
############################################
resource "aws_kms_key" "data" {
  count                   = var.enable_optional_data_kms ? 1 : 0
  description             = "App account: CMK for application data (S3/RDS/DynamoDB/OpenSearch/SNS/SQS/Lambda)"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  # Explicit policy: allow only common service integrations in THIS account
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Sid : "EnableRootAdmin",
        Effect : "Allow",
        Principal : { AWS : "arn:aws:iam::${data.aws_caller_identity.this.account_id}:root" },
        Action : "kms:*",
        Resource : "*"
      },
      # S3
      {
        Sid : "AllowS3ViaService",
        Effect : "Allow",
        Principal : "*",
        Action : [
          "kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*",
          "kms:GenerateDataKey*", "kms:DescribeKey"
        ],
        Resource : "*",
        Condition : {
          "StringLike" : { "kms:ViaService" : "s3.*.amazonaws.com" },
          "StringEquals" : { "aws:SourceAccount" : data.aws_caller_identity.this.account_id }
        }
      },
      # RDS (incl. Aurora)
      {
        Sid : "AllowRDSViaService",
        Effect : "Allow",
        Principal : "*",
        Action : [
          "kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*",
          "kms:GenerateDataKey*", "kms:DescribeKey"
        ],
        Resource : "*",
        Condition : {
          "StringLike" : { "kms:ViaService" : "rds.*.amazonaws.com" },
          "StringEquals" : { "aws:SourceAccount" : data.aws_caller_identity.this.account_id }
        }
      },
      # DynamoDB
      {
        Sid : "AllowDynamoDBViaService",
        Effect : "Allow",
        Principal : "*",
        Action : [
          "kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*",
          "kms:GenerateDataKey*", "kms:DescribeKey"
        ],
        Resource : "*",
        Condition : {
          "StringLike" : { "kms:ViaService" : "dynamodb.*.amazonaws.com" },
          "StringEquals" : { "aws:SourceAccount" : data.aws_caller_identity.this.account_id }
        }
      },
      # OpenSearch
      {
        Sid : "AllowOpenSearchViaService",
        Effect : "Allow",
        Principal : "*",
        Action : [
          "kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*",
          "kms:GenerateDataKey*", "kms:DescribeKey"
        ],
        Resource : "*",
        Condition : {
          "StringLike" : { "kms:ViaService" : "es.*.amazonaws.com" },
          "StringEquals" : { "aws:SourceAccount" : data.aws_caller_identity.this.account_id }
        }
      },
      # SNS
      {
        Sid : "AllowSNSViaService",
        Effect : "Allow",
        Principal : "*",
        Action : [
          "kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*",
          "kms:GenerateDataKey*", "kms:DescribeKey"
        ],
        Resource : "*",
        Condition : {
          "StringLike" : { "kms:ViaService" : "sns.*.amazonaws.com" },
          "StringEquals" : { "aws:SourceAccount" : data.aws_caller_identity.this.account_id }
        }
      },
      # SQS
      {
        Sid : "AllowSQSViaService",
        Effect : "Allow",
        Principal : "*",
        Action : [
          "kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*",
          "kms:GenerateDataKey*", "kms:DescribeKey"
        ],
        Resource : "*",
        Condition : {
          "StringLike" : { "kms:ViaService" : "sqs.*.amazonaws.com" },
          "StringEquals" : { "aws:SourceAccount" : data.aws_caller_identity.this.account_id }
        }
      },
      # Lambda (for env var encryption, etc.)
      {
        Sid : "AllowLambdaViaService",
        Effect : "Allow",
        Principal : "*",
        Action : [
          "kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*",
          "kms:GenerateDataKey*", "kms:DescribeKey"
        ],
        Resource : "*",
        Condition : {
          "StringLike" : { "kms:ViaService" : "lambda.*.amazonaws.com" },
          "StringEquals" : { "aws:SourceAccount" : data.aws_caller_identity.this.account_id }
        }
      }
    ]
  })
}

resource "aws_kms_alias" "data" {
  count         = var.enable_optional_data_kms ? 1 : 0
  name          = "alias/${var.alias_prefix}-data"
  target_key_id = aws_kms_key.data[0].key_id
}
