# Tagging Enforcement Module

## Purpose

Organization-level SCP that denies resource creates without required tags (e.g.,
Environment, Owner, CostCenter). Prevents “untaggable by default” resources from
being created in the first place.

> Why is this outside the main SCP module?  I kept it as a separate module for
  practical reasons: different rollout cadence (pilot per OU), different
  required_tag_keys per OU/account, easy temporary exception tag handling, and
  to avoid bloating the merged guardrail policy. It also keeps change reviews
  cleaner (“we’re only changing tag rules, not region/encryption/CloudTrail
  controls”).

## Example

```hcl
module "tagging_enforcement" {
  source    = "./modules/tagging_enforcement"
  providers = { aws = aws.security }

  target_id         = data.aws_caller_identity.app.account_id   # or OU id
  required_tag_keys = ["Environment","Owner","CostCenter"]
}
}
```

## Notes

-	Expand the action list in the policy to cover more services over time.
-	For a gentler rollout, pair with AWS Config + EventBridge to notify/auto-tag
  before enforcing.

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
| [aws_organizations_policy.require_tags](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy) | resource |
| [aws_organizations_policy_attachment.attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_required_tag_keys"></a> [required\_tag\_keys](#input\_required\_tag\_keys) | Tag keys that must be present on resource creation | `list(string)` | n/a | yes |
| <a name="input_target_id"></a> [target\_id](#input\_target\_id) | Organizations target to attach policy (OU id or account id) | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_policy_id"></a> [policy\_id](#output\_policy\_id) | n/a |
<!-- END_TF_DOCS -->
