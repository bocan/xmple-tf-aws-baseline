output "log_kms_key_arn" {
  description = "ARN of the CloudWatch Logs CMK."
  value       = aws_kms_key.logs.arn
}

output "ebs_default_kms_key_arn" {
  description = "ARN of the default EBS encryption CMK."
  value       = aws_kms_key.ebs.arn
}

output "data_kms_key_arn" {
  description = "ARN of the optional data CMK (null if not created)."
  value       = try(aws_kms_key.data[0].arn, null)
}
