output "policy_ids" {
  value = {
    guardrails_merged = aws_organizations_policy.guardrails_merged.id
  }
}
