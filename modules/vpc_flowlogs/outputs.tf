output "flow_logs_bucket_arn" {
  description = "(sink) ARN of the central VPC Flow Logs S3 bucket. Null in source mode."
  value       = try(aws_s3_bucket.flow[0].arn, null)
}

output "access_logs_bucket_arn" {
  description = "(sink) ARN of the access-logs bucket for the central flow-logs bucket. Null in source mode."
  value       = try(aws_s3_bucket.access_logs[0].arn, null)
}
