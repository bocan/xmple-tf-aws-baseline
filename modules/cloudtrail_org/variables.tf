# Basic naming / toggles
variable "bucket_name" {
  description = "Name of the central CloudTrail S3 bucket (in Security account)."
  type        = string
}

variable "access_logs_bucket_name" {
  description = "Name of the S3 bucket that will store access logs for the CloudTrail bucket."
  type        = string
  default     = "org-cloudtrail-s3-access-logs"
}

variable "cloudwatch_log_group_name" {
  description = "CloudWatch Logs group name used for CloudTrail streaming."
  type        = string
  default     = "/org/cloudtrail"
}

variable "cloudwatch_log_retention_days" {
  description = "Retention period (days) for the CloudWatch Logs group. Set >= 365 for compliance rules."
  type        = number
  default     = 400
}

variable "s3_object_lifecycle_days" {
  description = "Number of days before transitioning objects to Intelligent Tiering (or archive). Also used for noncurrent versions."
  type        = number
  default     = 30
}

variable "enable_crr" {
  description = "Enable cross-region replication (CRR) for the CloudTrail bucket. Set true only if we have a destination bucket and reason."
  type        = bool
  default     = false
}

variable "crr_destination_bucket_arn" {
  description = "ARN of the cross-region replication destination bucket (required if enable_crr = true)."
  type        = string
  default     = null
}

# KMS inputs (consumed; NOT creating keys here)
variable "trail_bucket_kms_key_arn" {
  description = "ARN of the KMS key to use for encrypting the CloudTrail S3 bucket (SSE-KMS)."
  type        = string
}

variable "access_logs_bucket_kms_key_arn" {
  description = "ARN of the KMS key to use for encrypting the CloudTrail access-logs S3 bucket."
  type        = string
}

variable "cloudwatch_kms_key_arn" {
  description = "ARN of the KMS key to use for encrypting the CloudWatch Log Group for CloudTrail."
  type        = string
}

variable "sns_kms_key_arn" {
  description = "ARN of the KMS key to use for encrypting the SNS topic used for CloudTrail delivery notifications."
  type        = string
}
