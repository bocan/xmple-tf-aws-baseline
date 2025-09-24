variable "central_logs_bucket_arn" {
  type        = string
  description = "Central logging bucket ARN in the Logging account."
}

variable "log_kms_key_arn" {
  type        = string
  description = "KMS key ARN used for CloudWatch Logs encryption in this account."
}

variable "log_retention_days" {
  type        = number
  description = "Retention in days for account log groups."
}
