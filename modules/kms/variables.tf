variable "enable_optional_data_kms" {
  description = "Create an additional CMK for application data (S3/RDS/DynamoDB/OpenSearch/SNS/SQS/Lambda)"
  type        = bool
  default     = false
}

variable "alias_prefix" {
  description = "Prefix for KMS aliases to make keys easily discoverable (e.g., 'baseline' => alias/baseline-logs, etc.)"
  type        = string
  default     = "baseline"
}
