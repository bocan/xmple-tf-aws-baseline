# VPC Flowlogs Module

## Purpose

Centralize VPC Flow Logs:

- In the LOGGING account (mode="sink"): create a central S3 bucket for VPC Flow Logs.
    * SSE-KMS using a provided CMK (do NOT create keys here)
    * Public Access Block, Versioning, ACLs disabled (BucketOwnerEnforced)
    * Lifecycle incl. abort incomplete multipart uploads
    * Access logging to a separate (encrypted) access-logs bucket
    * Optional S3 notifications to an SNS topic (must be encrypted outside this module)
    * Bucket policy allows ONLY a named delivery role in approved source accounts to PutObject
    * Optional cross-region replication (CRR) when our org requires it

- In the APP account (mode="source"): create an IAM role for VPC Flow Logs delivery
    * Attach least-priv policy for S3 write to the central bucket
    * Enable VPC Flow Logs for every VPC, writing to the central bucket

> No KMS keys created here. The sink consumes CMK ARNs for both buckets.

## Example

```hcl
# Logging (sink)
module "vpc_flowlogs_sink" {
  source    = "./modules/vpc_flowlogs"
  providers = { aws = aws.logging }

  mode                           = "sink"
  bucket_name                    = "org-flow-logs-central"
  flow_logs_bucket_kms_key_arn   = var.logging_kms_flow_logs_bucket_key_arn
  access_logs_bucket_name        = "org-flow-logs-s3-access-logs"
  access_logs_bucket_kms_key_arn = var.logging_kms_access_logs_key_arn

  allowed_account_ids = [data.aws_caller_identity.app.account_id]
  writer_role_name    = "vpc-flowlogs-to-logging-s3"

  enable_notifications = true
  sns_topic_arn        = var.logging_notifications_sns_topic_arn
}

# App (source)
module "vpc_flowlogs_source" {
  source    = "./modules/vpc_flowlogs"
  providers = { aws = aws.app }

  mode                 = "source"
  writer_role_name     = "vpc-flowlogs-to-logging-s3"
  flow_logs_bucket_arn = module.vpc_flowlogs_sink.flow_logs_bucket_arn
}
```

## Notes

-	If you only want certain VPCs, replace the data "aws_vpcs" with a list variable
  and for-each.

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
| [aws_flow_log.to_central](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_iam_role.crr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.delivery](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.crr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.delivery](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_s3_bucket.access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.flow](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_lifecycle_configuration.flow](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.flow](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_notification.access_logs_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_s3_bucket_notification.flow_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_s3_bucket_ownership_controls.access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_ownership_controls.flow](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.flow_allow_app_roles](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.flow](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_replication_configuration.flow](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_replication_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.flow](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.flow](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_vpcs.all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpcs) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_logs_bucket_kms_key_arn"></a> [access\_logs\_bucket\_kms\_key\_arn](#input\_access\_logs\_bucket\_kms\_key\_arn) | (sink) ARN of the KMS key used to encrypt the access-logs bucket. | `string` | `null` | no |
| <a name="input_access_logs_bucket_name"></a> [access\_logs\_bucket\_name](#input\_access\_logs\_bucket\_name) | (sink) Name of the S3 bucket that stores access logs for the central VPC Flow Logs bucket. | `string` | `"org-flow-logs-s3-access-logs"` | no |
| <a name="input_allowed_account_ids"></a> [allowed\_account\_ids](#input\_allowed\_account\_ids) | (sink) App account IDs allowed to write via the specified delivery role. | `list(string)` | `[]` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | (sink) Name of the central S3 bucket that will store VPC Flow Logs. | `string` | `null` | no |
| <a name="input_crr_destination_bucket_arn"></a> [crr\_destination\_bucket\_arn](#input\_crr\_destination\_bucket\_arn) | (sink) Destination bucket ARN for CRR. Required if enable\_crr = true. | `string` | `null` | no |
| <a name="input_enable_crr"></a> [enable\_crr](#input\_enable\_crr) | (sink) Enable cross-region replication for the central VPC Flow Logs bucket. | `bool` | `false` | no |
| <a name="input_enable_notifications"></a> [enable\_notifications](#input\_enable\_notifications) | (sink) If true, enable S3 event notifications for ObjectCreated to the provided SNS topic. | `bool` | `false` | no |
| <a name="input_flow_logs_bucket_arn"></a> [flow\_logs\_bucket\_arn](#input\_flow\_logs\_bucket\_arn) | (source) ARN of the central S3 bucket (in Logging account) to receive flow logs. | `string` | `null` | no |
| <a name="input_flow_logs_bucket_kms_key_arn"></a> [flow\_logs\_bucket\_kms\_key\_arn](#input\_flow\_logs\_bucket\_kms\_key\_arn) | (sink) ARN of the KMS key used to encrypt the central VPC Flow Logs bucket (SSE-KMS). | `string` | `null` | no |
| <a name="input_mode"></a> [mode](#input\_mode) | Use "sink" in the Logging account or "source" in the App account. | `string` | n/a | yes |
| <a name="input_replica_kms_key_arn"></a> [replica\_kms\_key\_arn](#input\_replica\_kms\_key\_arn) | (sink) KMS key ARN in the DESTINATION region to encrypt replicas. Required if enable\_crr = true. | `string` | `null` | no |
| <a name="input_s3_object_lifecycle_days"></a> [s3\_object\_lifecycle\_days](#input\_s3\_object\_lifecycle\_days) | (sink) Days before objects transition to INTELLIGENT\_TIERING; used for current and noncurrent versions. | `number` | `30` | no |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | (sink) SNS topic ARN for S3 event notifications. Required if enable\_notifications = true. | `string` | `null` | no |
| <a name="input_writer_role_name"></a> [writer\_role\_name](#input\_writer\_role\_name) | (sink+source) Name of the IAM role (in app accounts) that the VPC Flow Logs service will assume to write to this bucket. | `string` | `"vpc-flowlogs-to-logging-s3"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_access_logs_bucket_arn"></a> [access\_logs\_bucket\_arn](#output\_access\_logs\_bucket\_arn) | (sink) ARN of the access-logs bucket for the central flow-logs bucket. Null in source mode. |
| <a name="output_flow_logs_bucket_arn"></a> [flow\_logs\_bucket\_arn](#output\_flow\_logs\_bucket\_arn) | (sink) ARN of the central VPC Flow Logs S3 bucket. Null in source mode. |
<!-- END_TF_DOCS -->
