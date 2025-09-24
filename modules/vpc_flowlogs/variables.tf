# Shared
variable "mode" {
  description = "Use \"sink\" in the Logging account or \"source\" in the App account."
  type        = string
}

# SINK (Logging account) inputs
variable "bucket_name" {
  description = "(sink) Name of the central S3 bucket that will store VPC Flow Logs."
  type        = string
  default     = null
}

variable "flow_logs_bucket_kms_key_arn" {
  description = "(sink) ARN of the KMS key used to encrypt the central VPC Flow Logs bucket (SSE-KMS)."
  type        = string
  default     = null
}

variable "access_logs_bucket_name" {
  description = "(sink) Name of the S3 bucket that stores access logs for the central VPC Flow Logs bucket."
  type        = string
  default     = "org-flow-logs-s3-access-logs"
}

variable "access_logs_bucket_kms_key_arn" {
  description = "(sink) ARN of the KMS key used to encrypt the access-logs bucket."
  type        = string
  default     = null
}

variable "allowed_account_ids" {
  description = "(sink) App account IDs allowed to write via the specified delivery role."
  type        = list(string)
  default     = []
}

variable "writer_role_name" {
  description = "(sink+source) Name of the IAM role (in app accounts) that the VPC Flow Logs service will assume to write to this bucket."
  type        = string
  default     = "vpc-flowlogs-to-logging-s3"
}

variable "s3_object_lifecycle_days" {
  description = "(sink) Days before objects transition to INTELLIGENT_TIERING; used for current and noncurrent versions."
  type        = number
  default     = 30
}

variable "enable_notifications" {
  description = "(sink) If true, enable S3 event notifications for ObjectCreated to the provided SNS topic."
  type        = bool
  default     = false
}

variable "sns_topic_arn" {
  description = "(sink) SNS topic ARN for S3 event notifications. Required if enable_notifications = true."
  type        = string
  default     = null
}

variable "enable_crr" {
  description = "(sink) Enable cross-region replication for the central VPC Flow Logs bucket."
  type        = bool
  default     = false
}

variable "crr_destination_bucket_arn" {
  description = "(sink) Destination bucket ARN for CRR. Required if enable_crr = true."
  type        = string
  default     = null
}

variable "replica_kms_key_arn" {
  description = "(sink) KMS key ARN in the DESTINATION region to encrypt replicas. Required if enable_crr = true."
  type        = string
  default     = null
}

# SOURCE (App account) inputs
variable "flow_logs_bucket_arn" {
  description = "(source) ARN of the central S3 bucket (in Logging account) to receive flow logs."
  type        = string
  default     = null
}
