variable "target_id" {
  type        = string
  description = "Organizations target to attach policy (OU id or account id)"
}

variable "required_tag_keys" {
  type        = list(string)
  description = "Tag keys that must be present on resource creation"
}
