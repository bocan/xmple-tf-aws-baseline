output "cwl_destination_arn" {
  value       = try(aws_cloudwatch_log_destination.sink[0].arn, null)
  description = "(sink) Destination ARN to use from app accounts"
}
