output "log_kms_key_arn" {
  value = aws_kms_key.log.arn
}

output "ebs_default_kms_key_arn" {
  value = aws_kms_key.ebs_default.arn
}

output "data_kms_key_arn" {
  value = try(aws_kms_key.data[0].arn, null)
}
