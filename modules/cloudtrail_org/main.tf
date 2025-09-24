###########################
# Data: current account (module runs in the Security account)
###########################
# Using the module's provider context
data "aws_caller_identity" "this" {}

###########################
# S3: access logs bucket
# - versioned
# - ownership enforced (no ACLs)
# - SSE-KMS using provided key
# - public access block
# - lifecycle (with abort for multipart uploads)
# - (optional) notifications to same SNS topic
###########################
resource "aws_s3_bucket" "access_logs" {
  #checkov:skip=CKV_AWS_144:S3 cross-region replication is out-of-scope.
  bucket = var.access_logs_bucket_name
  # keep defaults; ACLs disabled via ownership controls below
}

resource "aws_s3_bucket_ownership_controls" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  rule { object_ownership = "BucketOwnerEnforced" } # disables ACLs (CKV2_AWS_65)
}

resource "aws_s3_bucket_versioning" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.access_logs_bucket_kms_key_arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket                  = aws_s3_bucket.access_logs.id
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket_lifecycle_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    id     = "access-logs-intelligent-tiering"
    status = "Enabled"

    filter { prefix = "" } # target entire bucket

    transition {
      days          = var.s3_object_lifecycle_days
      storage_class = "INTELLIGENT_TIERING"
    }

    noncurrent_version_transition {
      noncurrent_days = var.s3_object_lifecycle_days
      storage_class   = "INTELLIGENT_TIERING"
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

###########################
# S3: main CloudTrail bucket
# - ownership enforced
# - versioning
# - SSE-KMS using provided key
# - public access block
# - lifecycle rule + abort for multipart
# - access logging -> access_logs bucket
###########################
resource "aws_s3_bucket" "trail" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_ownership_controls" "trail" {
  bucket = aws_s3_bucket.trail.id
  rule { object_ownership = "BucketOwnerEnforced" } # disables ACLs
}

resource "aws_s3_bucket_versioning" "trail" {
  bucket = aws_s3_bucket.trail.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "trail" {
  bucket = aws_s3_bucket.trail.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.trail_bucket_kms_key_arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "trail" {
  bucket                  = aws_s3_bucket.trail.id
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket_lifecycle_configuration" "trail" {
  bucket = aws_s3_bucket.trail.id

  rule {
    id     = "trail-intelligent-tiering"
    status = "Enabled"

    filter { prefix = "" } # target entire bucket

    transition {
      days          = var.s3_object_lifecycle_days
      storage_class = "INTELLIGENT_TIERING"
    }

    noncurrent_version_transition {
      noncurrent_days = var.s3_object_lifecycle_days
      storage_class   = "INTELLIGENT_TIERING"
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_logging" "trail" {
  bucket        = aws_s3_bucket.trail.id
  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "s3-access-logs/"
}

###########################
# SNS topic for CloudTrail delivery (KMS-encrypted using provided key)
# - encryption at rest
# - allows other accounts/services to publish as needed (tighten policy later)
###########################
resource "aws_sns_topic" "trail_notifications" {
  name              = "cloudtrail-delivery"
  kms_master_key_id = var.sns_kms_key_arn
}

###########################
# S3 bucket notifications - send object created events to the SNS topic
# (both trail and access_logs get notifications so checks are happy)
###########################
resource "aws_s3_bucket_notification" "trail_events" {
  bucket = aws_s3_bucket.trail.id

  topic {
    topic_arn = aws_sns_topic.trail_notifications.arn
    events    = ["s3:ObjectCreated:*"]
  }
}

resource "aws_s3_bucket_notification" "access_logs_events" {
  bucket = aws_s3_bucket.access_logs.id

  topic {
    topic_arn = aws_sns_topic.trail_notifications.arn
    events    = ["s3:ObjectCreated:*"]
  }
}

###########################
# CloudWatch Logs group + IAM role for CloudTrail -> CloudWatch streaming
# - retention set to var.cloudwatch_log_retention_days (>= 365 recommended)
# - CMK for encrypting log group is provided by caller
###########################
resource "aws_cloudwatch_log_group" "trail" {
  name              = var.cloudwatch_log_group_name
  retention_in_days = var.cloudwatch_log_retention_days
  kms_key_id        = var.cloudwatch_kms_key_arn
}

resource "aws_iam_role" "cloudtrail_to_cw" {
  name = "CloudTrailToCloudWatchLogs"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "cloudtrail.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "cloudtrail_to_cw" {
  role = aws_iam_role.cloudtrail_to_cw.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      Resource = "${aws_cloudwatch_log_group.trail.arn}:*"
    }]
  })
}

###########################
# S3 bucket policy to allow CloudTrail service to PutObject
# - requires x-amz-acl = bucket-owner-full-control
# - restricts source account (this Security account)
###########################
resource "aws_s3_bucket_policy" "trail" {
  bucket = aws_s3_bucket.trail.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowCloudTrailWrite",
        Effect    = "Allow",
        Principal = { Service = "cloudtrail.amazonaws.com" },
        Action    = "s3:PutObject",
        Resource  = "${aws_s3_bucket.trail.arn}/AWSLogs/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"      = "bucket-owner-full-control",
            "aws:SourceAccount" = data.aws_caller_identity.this.account_id
          }
        }
      }
    ]
  })
}

###########################
# Optional: Cross-region replication (CRR)
# - Only created when enable_crr = true
# - Assumes destination bucket exists and we pass its ARN
###########################
resource "aws_iam_role" "crr" {
  count = var.enable_crr ? 1 : 0
  name  = "CloudTrailBucketReplicationRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "s3.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "crr" {
  count = var.enable_crr ? 1 : 0
  role  = aws_iam_role.crr[0].id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:GetReplicationConfiguration", "s3:ListBucket"],
        Resource = aws_s3_bucket.trail.arn
      },
      {
        Effect   = "Allow",
        Action   = ["s3:GetObjectVersion", "s3:GetObjectVersionAcl", "s3:GetObjectVersionTagging"],
        Resource = "${aws_s3_bucket.trail.arn}/*"
      },
      {
        Effect   = "Allow",
        Action   = ["s3:ReplicateObject", "s3:ReplicateDelete", "s3:ReplicateTags", "s3:ObjectOwnerOverrideToBucketOwner"],
        Resource = "${var.crr_destination_bucket_arn}/*"
      },
      {
        Effect   = "Allow",
        Action   = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"],
        Resource = var.trail_bucket_kms_key_arn
      }
    ]
  })
}

resource "aws_s3_bucket_replication_configuration" "trail" {
  count  = var.enable_crr ? 1 : 0
  bucket = aws_s3_bucket.trail.id
  role   = aws_iam_role.crr[0].arn

  rule {
    id     = "crr-cloudtrail"
    status = "Enabled"

    filter {} # entire bucket

    destination {
      bucket        = var.crr_destination_bucket_arn
      storage_class = "STANDARD"

      encryption_configuration {
        replica_kms_key_id = var.trail_bucket_kms_key_arn
      }
    }
  }
}

###########################
# CloudTrail (org trail) resource
# - encrypted with provided KMS
# - configured to stream to CloudWatch Logs and publish notifications to SNS
###########################
resource "aws_cloudtrail" "org" {
  name                          = "organization-trail"
  is_organization_trail         = true
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true

  s3_bucket_name             = aws_s3_bucket.trail.id
  kms_key_id                 = var.trail_bucket_kms_key_arn
  sns_topic_name             = aws_sns_topic.trail_notifications.name
  cloud_watch_logs_group_arn = aws_cloudwatch_log_group.trail.arn
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_to_cw.arn

  event_selector {
    include_management_events = true
    read_write_type           = "All"
  }
}
