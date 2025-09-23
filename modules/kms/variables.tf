variable "enable_optional_data_kms" {
  type        = bool
  description = "Whether to create a separate CMK for application data services."
  default     = true
}
