# CloudWatch Log Module

## Purpose

Centralize CloudWatch Logs from the App account into the Logging account via a
Logs Destination:

-	Sink mode (Logging): create Kinesis stream, Logs Destination, and destination
  policy allowing the app account to subscribe.
-	Source mode (App): create/encrypt log groups (with provided CMK) and
  subscription filters to the sink.

> This module does not create KMS keys; it consumes a CMK ARN for log group
  encryption (from kms module).

## Example

```hcl
# Logging account
module "cwl_sink" {
  source    = "./modules/cwl_forwarding"
  providers = { aws = aws.logging }
  mode                = "sink"
  destination_name    = "to-logging-central"
  allow_source_acctid = data.aws_caller_identity.app.account_id
}

# App account
module "cwl_source" {
  source    = "./modules/cwl_forwarding"
  providers = { aws = aws.app }
  mode               = "source"
  log_group_name     = "/account/baseline"
  log_kms_key_arn    = module.kms.log_kms_key_arn
  log_retention_days = 90
  destination_arn    = module.cwl_sink.cwl_destination_arn
}
}
```

## Notes

-	Kinesis stream is minimal (1 shard). Scale per volume.
-	If multiple app accounts subscribe, widen allow_source_acctid policy or clone destinations per OU.

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
| [aws_cloudwatch_log_destination.sink](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_destination) | resource |
| [aws_cloudwatch_log_destination_policy.sink_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_destination_policy) | resource |
| [aws_cloudwatch_log_group.src](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_subscription_filter.to_sink](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_subscription_filter) | resource |
| [aws_iam_role.cwl_to_kinesis](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.cwl_to_kinesis](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_kinesis_stream.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kinesis_stream) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allow_source_acctid"></a> [allow\_source\_acctid](#input\_allow\_source\_acctid) | n/a | `string` | `null` | no |
| <a name="input_destination_arn"></a> [destination\_arn](#input\_destination\_arn) | n/a | `string` | `null` | no |
| <a name="input_destination_name"></a> [destination\_name](#input\_destination\_name) | Sink Inputs | `string` | `null` | no |
| <a name="input_log_group_name"></a> [log\_group\_name](#input\_log\_group\_name) | Source Inputs | `string` | `null` | no |
| <a name="input_log_kms_key_arn"></a> [log\_kms\_key\_arn](#input\_log\_kms\_key\_arn) | n/a | `string` | `null` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | n/a | `number` | `90` | no |
| <a name="input_mode"></a> [mode](#input\_mode) | "sink" (Logging) or "source" (App) | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cwl_destination_arn"></a> [cwl\_destination\_arn](#output\_cwl\_destination\_arn) | (sink) Destination ARN to use from app accounts |
<!-- END_TF_DOCS -->
