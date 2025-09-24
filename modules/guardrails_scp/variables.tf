variable "org_id" {
  type = string
}

variable "region_allowlist" {
  type = list(string)
}

variable "protected_kms_arn" {
  type        = string
  description = "Specific KMS key ARN (log key) that must not be disabled or scheduled for deletion."
}
