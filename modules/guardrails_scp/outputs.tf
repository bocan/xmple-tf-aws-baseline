output "policy_ids" {
  value = {
    deny_cloudtrail_disable      = aws_organizations_policy.deny_cloudtrail_disable.id
    deny_public_s3               = aws_organizations_policy.deny_public_s3.id
    require_encryption_on_create = aws_organizations_policy.require_encryption_on_create.id
    restrict_regions             = aws_organizations_policy.restrict_regions.id
    protect_log_keys             = aws_organizations_policy.protect_log_keys.id
    deny_non_org_principals      = aws_organizations_policy.deny_non_org_principals.id
  }
}
