output "cloudtrail_bucket_arn" {
  description = "ARN of the central CloudTrail bucket (Security account)."
  value       = aws_s3_bucket.trail.arn
}

output "access_logs_bucket_arn" {
  description = "ARN of the CloudTrail access-logs bucket (Security account)."
  value       = aws_s3_bucket.access_logs.arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic used for CloudTrail delivery notifications."
  value       = aws_sns_topic.trail_notifications.arn
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch Logs group used for CloudTrail streaming."
  value       = aws_cloudwatch_log_group.trail.arn
}
