# CloudTrail Module

## Important

This module assumes it is executed in the Security account and that KMS keys
(for S3/CW/SNS) are managed centrally and passed in.

## Purpose

Create a secure Organization CloudTrail in the Security account, plus supporting
resources:

-	Central S3 buckets (trail + access-logs), SSE-KMS, PAB, versioning, lifecycle +
  abort MPU.
-	CloudWatch Logs integration (KMS-encrypted).
-	SNS notifications (KMS-encrypted).
-	Optional cross-region replication (CRR) behind a flag.
-	Consumes KMS ARNs (does not create keys).

## Example

```hcl
module "cloudtrail_org" {
  source    = "./modules/cloudtrail_org"
  providers = { aws = aws.security }

  bucket_name                    = "org-cloudtrail-central"
  access_logs_bucket_name        = "org-cloudtrail-s3-access-logs"
  cloudwatch_log_group_name      = "/org/cloudtrail"
  cloudwatch_log_retention_days  = 400

  trail_bucket_kms_key_arn       = var.security_kms_trail_bucket_key_arn
  access_logs_bucket_kms_key_arn = var.security_kms_access_logs_key_arn
  cloudwatch_kms_key_arn         = var.security_kms_cwlogs_key_arn
  sns_kms_key_arn                = var.security_kms_sns_key_arn

  enable_crr                     = false
}
```

## Notes

-	Keep CRR (cross-region replication)  off unless mandated; it adds cost and
  complexity.
-	S3 bucket notifications are enabled to satisfy static checks; wire the SNS
  subscription downstream if needed.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= v1.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.14 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 6.14 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudtrail.org](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudtrail) | resource |
| [aws_cloudwatch_log_group.trail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_role.cloudtrail_to_cw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.crr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.cloudtrail_to_cw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.crr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_s3_bucket.access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.trail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_lifecycle_configuration.trail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.trail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_notification.access_logs_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_s3_bucket_notification.trail_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_s3_bucket_ownership_controls.access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_ownership_controls.trail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.trail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.trail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_replication_configuration.trail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_replication_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.trail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.trail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_sns_topic.trail_notifications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_caller_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_logs_bucket_kms_key_arn"></a> [access\_logs\_bucket\_kms\_key\_arn](#input\_access\_logs\_bucket\_kms\_key\_arn) | ARN of the KMS key to use for encrypting the CloudTrail access-logs S3 bucket. | `string` | n/a | yes |
| <a name="input_access_logs_bucket_name"></a> [access\_logs\_bucket\_name](#input\_access\_logs\_bucket\_name) | Name of the S3 bucket that will store access logs for the CloudTrail bucket. | `string` | `"org-cloudtrail-s3-access-logs"` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Name of the central CloudTrail S3 bucket (in Security account). | `string` | n/a | yes |
| <a name="input_cloudwatch_kms_key_arn"></a> [cloudwatch\_kms\_key\_arn](#input\_cloudwatch\_kms\_key\_arn) | ARN of the KMS key to use for encrypting the CloudWatch Log Group for CloudTrail. | `string` | n/a | yes |
| <a name="input_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#input\_cloudwatch\_log\_group\_name) | CloudWatch Logs group name used for CloudTrail streaming. | `string` | `"/org/cloudtrail"` | no |
| <a name="input_cloudwatch_log_retention_days"></a> [cloudwatch\_log\_retention\_days](#input\_cloudwatch\_log\_retention\_days) | Retention period (days) for the CloudWatch Logs group. Set >= 365 for compliance rules. | `number` | `400` | no |
| <a name="input_crr_destination_bucket_arn"></a> [crr\_destination\_bucket\_arn](#input\_crr\_destination\_bucket\_arn) | ARN of the cross-region replication destination bucket (required if enable\_crr = true). | `string` | `null` | no |
| <a name="input_enable_crr"></a> [enable\_crr](#input\_enable\_crr) | Enable cross-region replication (CRR) for the CloudTrail bucket. Set true only if we have a destination bucket and reason. | `bool` | `false` | no |
| <a name="input_s3_object_lifecycle_days"></a> [s3\_object\_lifecycle\_days](#input\_s3\_object\_lifecycle\_days) | Number of days before transitioning objects to Intelligent Tiering (or archive). Also used for noncurrent versions. | `number` | `30` | no |
| <a name="input_sns_kms_key_arn"></a> [sns\_kms\_key\_arn](#input\_sns\_kms\_key\_arn) | ARN of the KMS key to use for encrypting the SNS topic used for CloudTrail delivery notifications. | `string` | n/a | yes |
| <a name="input_trail_bucket_kms_key_arn"></a> [trail\_bucket\_kms\_key\_arn](#input\_trail\_bucket\_kms\_key\_arn) | ARN of the KMS key to use for encrypting the CloudTrail S3 bucket (SSE-KMS). | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_access_logs_bucket_arn"></a> [access\_logs\_bucket\_arn](#output\_access\_logs\_bucket\_arn) | ARN of the CloudTrail access-logs bucket (Security account). |
| <a name="output_cloudtrail_bucket_arn"></a> [cloudtrail\_bucket\_arn](#output\_cloudtrail\_bucket\_arn) | ARN of the central CloudTrail bucket (Security account). |
| <a name="output_cloudwatch_log_group_arn"></a> [cloudwatch\_log\_group\_arn](#output\_cloudwatch\_log\_group\_arn) | ARN of the CloudWatch Logs group used for CloudTrail streaming. |
| <a name="output_sns_topic_arn"></a> [sns\_topic\_arn](#output\_sns\_topic\_arn) | ARN of the SNS topic used for CloudTrail delivery notifications. |
<!-- END_TF_DOCS -->
