locals {
  is_sink   = lower(var.mode) == "sink"
  is_source = lower(var.mode) == "source"
}

############################
# SINK MODE (Logging account)
############################
resource "aws_s3_bucket" "flow" {
  count  = local.is_sink ? 1 : 0
  bucket = var.bucket_name
}

resource "aws_s3_bucket_ownership_controls" "flow" {
  count  = local.is_sink ? 1 : 0
  bucket = aws_s3_bucket.flow[0].id
  rule { object_ownership = "BucketOwnerEnforced" } # disables ACLs
}

resource "aws_s3_bucket_versioning" "flow" {
  count  = local.is_sink ? 1 : 0
  bucket = aws_s3_bucket.flow[0].id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "flow" {
  count  = local.is_sink ? 1 : 0
  bucket = aws_s3_bucket.flow[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.flow_logs_bucket_kms_key_arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "flow" {
  count                   = local.is_sink ? 1 : 0
  bucket                  = aws_s3_bucket.flow[0].id
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

# Lifecycle (entire bucket) + abort incomplete MPU — aligns with Checkov expectations
resource "aws_s3_bucket_lifecycle_configuration" "flow" {
  count  = local.is_sink ? 1 : 0
  bucket = aws_s3_bucket.flow[0].id

  rule {
    id     = "intelligent-tiering"
    status = "Enabled"

    filter { prefix = "" } # provider v6 requires one of {filter,prefix}

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

# Access-logs bucket for the central flow-logs bucket
resource "aws_s3_bucket" "access_logs" {
  #checkov:skip=CKV_AWS_144:S3 cross-region replication is out-of-scope.
  count  = local.is_sink ? 1 : 0
  bucket = var.access_logs_bucket_name
}

resource "aws_s3_bucket_ownership_controls" "access_logs" {
  count  = local.is_sink ? 1 : 0
  bucket = aws_s3_bucket.access_logs[0].id
  rule { object_ownership = "BucketOwnerEnforced" }
}

resource "aws_s3_bucket_versioning" "access_logs" {
  count  = local.is_sink ? 1 : 0
  bucket = aws_s3_bucket.access_logs[0].id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  count  = local.is_sink ? 1 : 0
  bucket = aws_s3_bucket.access_logs[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.access_logs_bucket_kms_key_arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  count                   = local.is_sink ? 1 : 0
  bucket                  = aws_s3_bucket.access_logs[0].id
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket_lifecycle_configuration" "access_logs" {
  count  = local.is_sink ? 1 : 0
  bucket = aws_s3_bucket.access_logs[0].id

  rule {
    id     = "access-logs-intelligent-tiering"
    status = "Enabled"

    filter { prefix = "" }

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

# Access logging for the central flow-logs bucket → to access_logs bucket
resource "aws_s3_bucket_logging" "flow" {
  count         = local.is_sink ? 1 : 0
  bucket        = aws_s3_bucket.flow[0].id
  target_bucket = aws_s3_bucket.access_logs[0].id
  target_prefix = "s3-access-logs/"
}

# Optional S3 notifications (ObjectCreated) to SNS (if org mandates)
resource "aws_s3_bucket_notification" "flow_events" {
  count  = local.is_sink && var.enable_notifications && var.sns_topic_arn != null ? 1 : 0
  bucket = aws_s3_bucket.flow[0].id

  topic {
    topic_arn = var.sns_topic_arn
    events    = ["s3:ObjectCreated:*"]
  }
}

# Optional S3 notifications for the ACCESS-LOGS bucket (ObjectCreated) → SNS
resource "aws_s3_bucket_notification" "access_logs_events" {
  count  = local.is_sink && var.enable_notifications && var.sns_topic_arn != null ? 1 : 0
  bucket = aws_s3_bucket.access_logs[0].id

  topic {
    topic_arn = var.sns_topic_arn
    events    = ["s3:ObjectCreated:*"]
  }
}

# Bucket policy: allow ONLY the named delivery role from approved app accounts to write
resource "aws_s3_bucket_policy" "flow_allow_app_roles" {
  count  = local.is_sink && length(var.allowed_account_ids) > 0 ? 1 : 0
  bucket = aws_s3_bucket.flow[0].id

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      # Allow PutObject from the specific delivery role(s) in approved accounts
      {
        Sid : "AllowPutByDeliveryRoles",
        Effect : "Allow",
        Principal : {
          AWS : [
            for acct in var.allowed_account_ids :
            "arn:aws:iam::${acct}:role/${var.writer_role_name}"
          ]
        },
        Action : ["s3:PutObject", "s3:AbortMultipartUpload"],
        Resource : "${aws_s3_bucket.flow[0].arn}/*"
      }
    ]
  })
}

# Optional: Cross-Region Replication (CRR)
resource "aws_iam_role" "crr" {
  count = local.is_sink && var.enable_crr ? 1 : 0
  name  = "FlowLogsBucketReplicationRole"
  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [{
      Effect : "Allow",
      Principal : { Service : "s3.amazonaws.com" },
      Action : "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "crr" {
  count = local.is_sink && var.enable_crr ? 1 : 0
  role  = aws_iam_role.crr[0].id
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      { Effect : "Allow", Action : ["s3:GetReplicationConfiguration", "s3:ListBucket"], Resource : aws_s3_bucket.flow[0].arn },
      { Effect : "Allow", Action : ["s3:GetObjectVersion", "s3:GetObjectVersionAcl", "s3:GetObjectVersionTagging"], Resource : "${aws_s3_bucket.flow[0].arn}/*" },
      { Effect : "Allow", Action : ["s3:ReplicateObject", "s3:ReplicateDelete", "s3:ReplicateTags", "s3:ObjectOwnerOverrideToBucketOwner"], Resource : "${var.crr_destination_bucket_arn}/*" }
    ]
  })
}

resource "aws_s3_bucket_replication_configuration" "flow" {
  count  = local.is_sink && var.enable_crr ? 1 : 0
  bucket = aws_s3_bucket.flow[0].id
  role   = aws_iam_role.crr[0].arn

  rule {
    id     = "crr-flow-logs"
    status = "Enabled"
    filter {} # entire bucket

    destination {
      bucket        = var.crr_destination_bucket_arn
      storage_class = "STANDARD"

      # Use the destination-region CMK we pass in
      encryption_configuration {
        replica_kms_key_id = var.replica_kms_key_arn
      }
    }
  }
}

############################
# SOURCE MODE (App account)
############################
# Delivery role that the VPC Flow Logs service assumes
resource "aws_iam_role" "delivery" {
  count = local.is_source ? 1 : 0
  name  = var.writer_role_name
  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [{
      Effect : "Allow",
      Principal : { Service : "vpc-flow-logs.amazonaws.com" },
      Action : "sts:AssumeRole"
    }]
  })
}

# Least-priv policy: allow write to the central bucket only
resource "aws_iam_role_policy" "delivery" {
  count = local.is_source ? 1 : 0
  role  = aws_iam_role.delivery[0].id
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Sid : "AllowPutObjectsToCentralBucket",
        Effect : "Allow",
        Action : ["s3:PutObject", "s3:AbortMultipartUpload"],
        Resource : [
          var.flow_logs_bucket_arn,
          "${var.flow_logs_bucket_arn}/*"
        ]
      },
      {
        Sid : "AllowListCentralBucket",
        Effect : "Allow",
        Action : ["s3:ListBucket"],
        Resource : var.flow_logs_bucket_arn
      }
    ]
  })
}

# Discover all VPCs in this app account/region
data "aws_vpcs" "all" {
  count = local.is_source ? 1 : 0
}

# Enable Flow Logs to central S3 for every VPC
resource "aws_flow_log" "to_central" {
  count                = local.is_source ? length(data.aws_vpcs.all[0].ids) : 0
  vpc_id               = data.aws_vpcs.all[0].ids[count.index]
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = var.flow_logs_bucket_arn
  iam_role_arn         = aws_iam_role.delivery[0].arn
}
