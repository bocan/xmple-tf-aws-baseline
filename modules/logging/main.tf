# CloudWatch Logs account-level defaults (KMS + retention)
resource "aws_cloudwatch_log_group" "baseline_account_events" {
  name              = "/account/baseline"
  kms_key_id        = var.log_kms_key_arn
  retention_in_days = var.log_retention_days
}

# GuardDuty: enable detector ; associate with delegated admin (Security account).
# For production - Guardduty is better handled at the Org level.  See README.md
# Checkov doesn't like this...

resource "aws_guardduty_detector" "this" {
  #checkov:skip=CKV2_AWS_3: GuardDuty should managed org-wide in the Security account. Member accounts do not configure org auto-enable.
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

# In most orgs the Security account is already delegated admin and will auto-enroll members.
# If needed, invite + accept can be automated by Security side; here we just ensure detector is on.

# VPC Flow Logs: for each VPC in the account, enable flow logs to central S3 bucket (owned by Logging account).
# NOTE: This is a simple account-level pattern. In production you may drive this per-VPC module.
data "aws_vpcs" "all" {}

resource "aws_flow_log" "to_central_s3" {
  for_each = toset(data.aws_vpcs.all.ids)

  iam_role_arn    = aws_iam_role.vpc_flowlogs_delivery.arn
  log_destination = var.central_logs_bucket_arn
  traffic_type    = "ALL"
  vpc_id          = each.key

  log_destination_type = "s3"
  # For CloudWatch Logs destinations instead, set to "cloud-watch-logs" and provide log_group_name.
}

# IAM role to allow VPC Flow Logs service to write into the central bucket via bucket policy in Logging account.
resource "aws_iam_role" "vpc_flowlogs_delivery" {
  name               = "vpc-flowlogs-to-central-s3"
  assume_role_policy = data.aws_iam_policy_document.vpc_flowlogs_assume.json
}

data "aws_iam_policy_document" "vpc_flowlogs_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy" "vpc_flowlogs_delivery" {
  name = "vpc-flowlogs-s3-write"
  role = aws_iam_role.vpc_flowlogs_delivery.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid    = "AllowS3WriteCentral",
      Effect = "Allow",
      Action = ["s3:PutObject", "s3:AbortMultipartUpload", "s3:ListBucket", "s3:PutObjectAcl"],
      Resource = [
        var.central_logs_bucket_arn,
        "${var.central_logs_bucket_arn}/*"
      ]
    }]
  })
}
