resource "aws_organizations_policy" "guardrails_merged" {
  name = "GuardrailsMerged"
  type = "SERVICE_CONTROL_POLICY"
  content = templatefile("${path.module}/policies/guardrails-merged.json.tmpl", {
    allowed_regions     = var.allowed_regions
    protect_kms_key_arn = var.protect_kms_key_arn
    org_id              = var.org_id
  })
}

resource "aws_organizations_policy_attachment" "attach" {
  policy_id = aws_organizations_policy.guardrails_merged.id
  target_id = var.target_id
}
