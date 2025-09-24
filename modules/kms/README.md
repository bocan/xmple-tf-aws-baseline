# KMS Module

## Purpose

Provision customer-managed KMS keys in the App account:

-	Logs CMK for CloudWatch Logs.
-	EBS CMK and set EBS encryption by default + default CMK.
-	Optional Data CMK for service-integrated encryption
  (S3/RDS/DynamoDB/OpenSearch/SNS/SQS/Lambda).

Key policies are explicit and least-privileged (scoped via kms:ViaService +
aws:SourceAccount). No cross-account grants here.

## Example

```hcl
module "kms" {
  source = "./modules/kms"
  providers = { aws = aws.app }

  alias_prefix              = "app1"
  enable_optional_data_kms  = true
}
```

## Notes

-	Pair with SCP that denies disabling/deleting the logs CMK (done in scp_guardrails).
-	If CI/CD needs GenerateDataKey, extend the key policy with the specific role ARN(s).

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
| [aws_ebs_default_kms_key.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_default_kms_key) | resource |
| [aws_ebs_encryption_by_default.on](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_encryption_by_default) | resource |
| [aws_kms_alias.data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_alias.ebs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_alias.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key.ebs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_caller_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alias_prefix"></a> [alias\_prefix](#input\_alias\_prefix) | Prefix for KMS aliases to make keys easily discoverable (e.g., 'baseline' => alias/baseline-logs, etc.) | `string` | `"baseline"` | no |
| <a name="input_enable_optional_data_kms"></a> [enable\_optional\_data\_kms](#input\_enable\_optional\_data\_kms) | Create an additional CMK for application data (S3/RDS/DynamoDB/OpenSearch/SNS/SQS/Lambda) | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_data_kms_key_arn"></a> [data\_kms\_key\_arn](#output\_data\_kms\_key\_arn) | ARN of the optional data CMK (null if not created). |
| <a name="output_ebs_default_kms_key_arn"></a> [ebs\_default\_kms\_key\_arn](#output\_ebs\_default\_kms\_key\_arn) | ARN of the default EBS encryption CMK. |
| <a name="output_log_kms_key_arn"></a> [log\_kms\_key\_arn](#output\_log\_kms\_key\_arn) | ARN of the CloudWatch Logs CMK. |
<!-- END_TF_DOCS -->
