locals {
  is_sink   = lower(var.mode) == "sink"
  is_source = lower(var.mode) == "source"
}

# SINK: Logging account destination (Kinesis-based)
resource "aws_kinesis_stream" "logs" {
  count       = local.is_sink ? 1 : 0
  name        = "${var.destination_name}-stream"
  shard_count = 1
}

resource "aws_iam_role" "cwl_to_kinesis" {
  count = local.is_sink ? 1 : 0
  name  = "${var.destination_name}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect : "Allow",
      Principal : { Service : "logs.amazonaws.com" },
      Action : "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "cwl_to_kinesis" {
  count = local.is_sink ? 1 : 0
  role  = aws_iam_role.cwl_to_kinesis[0].id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect : "Allow",
      Action : ["kinesis:PutRecord", "kinesis:PutRecords", "kinesis:DescribeStream"],
      Resource : aws_kinesis_stream.logs[0].arn
    }]
  })
}

resource "aws_cloudwatch_log_destination" "sink" {
  count      = local.is_sink ? 1 : 0
  name       = var.destination_name
  role_arn   = aws_iam_role.cwl_to_kinesis[0].arn
  target_arn = aws_kinesis_stream.logs[0].arn
}

resource "aws_cloudwatch_log_destination_policy" "sink_policy" {
  count            = local.is_sink ? 1 : 0
  destination_name = aws_cloudwatch_log_destination.sink[0].name
  access_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid : "AllowAppAccount",
      Effect : "Allow",
      Principal : { AWS : "*" },
      Action : "logs:PutSubscriptionFilter",
      Resource : aws_cloudwatch_log_destination.sink[0].arn,
      Condition : {
        StringEquals : { "aws:SourceAccount" : var.allow_source_acctid },
        ArnLike : { "aws:SourceArn" : "arn:aws:logs:*:${var.allow_source_acctid}:log-group:*" }
      }
    }]
  })
}

# SOURCE: App account log group + subscription to Logging destination
resource "aws_cloudwatch_log_group" "src" {
  count             = local.is_source ? 1 : 0
  name              = var.log_group_name
  kms_key_id        = var.log_kms_key_arn
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_subscription_filter" "to_sink" {
  count           = local.is_source ? 1 : 0
  name            = "to-logging-destination"
  log_group_name  = aws_cloudwatch_log_group.src[0].name
  destination_arn = var.destination_arn
  filter_pattern  = ""
}
