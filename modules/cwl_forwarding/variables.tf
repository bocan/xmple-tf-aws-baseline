variable "mode" {
  type        = string
  description = "\"sink\" (Logging) or \"source\" (App)"
}

# Sink Inputs
variable "destination_name" {
  type    = string
  default = null
}
variable "allow_source_acctid" {
  type    = string
  default = null
}

# Source Inputs
variable "log_group_name" {
  type    = string
  default = null
}
variable "log_kms_key_arn" {
  type    = string
  default = null
}
variable "log_retention_days" {
  type    = number
  default = 90
}
variable "destination_arn" {
  type    = string
  default = null
}
