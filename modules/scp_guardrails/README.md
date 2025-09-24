# SCP Guardrails Module

## Purpose

A single merged SCP that applies core guardrails while staying well under the
5-attachments-per-target cap:

-	Deny principals outside the Organization (aws:PrincipalOrgID).
-	Deny CloudTrail tampering (stop/delete/update).
-	Deny public S3 ACLs / risky bucket policies (defence-in-depth; pair with
  account-level PAB).
-	Require encryption on create for common services (S3 EPUT, EBS, RDS,
  OpenSearch).
-	Restrict regions to an allow-list.
-	Protect the logs CMK from disable/delete/rotation off.

## Example

```hcl
module "scp_guardrails" {
  source    = "./modules/scp_guardrails"
  providers = { aws = aws.security }

  target_id           = data.aws_caller_identity.app.account_id   # or OU/root id
  allowed_regions     = ["eu-west-1","eu-west-2"]
  protect_kms_key_arn = module.kms.log_kms_key_arn
  org_id              = var.org_id
}
```

## Notes

-	If you need additional denies (e.g., DynamoDB table create without SSE), extend
  the JSON template but watch the SCP size limit (5 KB).
-	Use inheritance (attach at parent OU) to keep per-account attachments minimal.


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
| [aws_organizations_policy.guardrails_merged](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy) | resource |
| [aws_organizations_policy_attachment.attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_regions"></a> [allowed\_regions](#input\_allowed\_regions) | Approved regions | `list(string)` | n/a | yes |
| <a name="input_org_id"></a> [org\_id](#input\_org\_id) | Our AWS Organizations ID (e.g., o-abc123xyz) | `string` | n/a | yes |
| <a name="input_protect_kms_key_arn"></a> [protect\_kms\_key\_arn](#input\_protect\_kms\_key\_arn) | Logs KMS key ARN to protect from disable/delete | `string` | n/a | yes |
| <a name="input_target_id"></a> [target\_id](#input\_target\_id) | Root/OU/Account ID to attach the merged guardrail to | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_policy_ids"></a> [policy\_ids](#output\_policy\_ids) | n/a |
<!-- END_TF_DOCS -->
