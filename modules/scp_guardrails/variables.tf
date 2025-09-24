variable "target_id" {
  type        = string
  description = "Root/OU/Account ID to attach the merged guardrail to"
}

variable "allowed_regions" {
  type        = list(string)
  description = "Approved regions"
}

variable "protect_kms_key_arn" {
  type        = string
  description = "Logs KMS key ARN to protect from disable/delete"
}

variable "org_id" {
  type        = string
  description = "Our AWS Organizations ID (e.g., o-abc123xyz)"
}
