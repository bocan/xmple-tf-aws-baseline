# These SCPs are intended to be attached at the OU that contains this account.
# You can also attach at the account directly during bootstrap, then migrate to OU.

resource "aws_organizations_policy" "deny_cloudtrail_disable" {
  name    = "DenyCloudTrailDisable"
  type    = "SERVICE_CONTROL_POLICY"
  content = file("${path.module}/policies/deny-cloudtrail-disable.json")
}

resource "aws_organizations_policy" "deny_public_s3" {
  name    = "DenyPublicS3"
  type    = "SERVICE_CONTROL_POLICY"
  content = file("${path.module}/policies/deny-public-s3.json")
}

resource "aws_organizations_policy" "require_encryption_on_create" {
  name    = "RequireEncryptionOnCreate"
  type    = "SERVICE_CONTROL_POLICY"
  content = file("${path.module}/policies/require-encryption-on-create.json")
}

resource "aws_organizations_policy" "restrict_regions" {
  name = "RestrictRegions"
  type = "SERVICE_CONTROL_POLICY"
  content = templatefile("${path.module}/policies/restrict-regions.json.tmpl", {
    allowed = var.region_allowlist
  })
}

resource "aws_organizations_policy" "protect_log_keys" {
  name = "ProtectLogKmsKeys"
  type = "SERVICE_CONTROL_POLICY"
  content = templatefile("${path.module}/policies/protect-log-keys.json.tmpl", {
    kms_arn = var.protected_kms_arn
  })
}

# Extra. Block cross-org access.
resource "aws_organizations_policy" "deny_non_org_principals" {
  name = "DenyNonOrgPrincipals"
  type = "SERVICE_CONTROL_POLICY"
  content = templatefile("${path.module}/policies/deny-non-org-principals.json.tmpl", {
    org_id = var.org_id
  })
}
