
## Features

### Summary

- Single apply to three accounts using provider aliases.
-	Centralised logging
   -	CloudTrail: Org Trail in Security → central S3 (versioned, policy-limited).
   -	CloudWatch Logs: App account log groups (KMS + retention) → cross-account
      destination in Logging.
   -	VPC Flow Logs: App account → S3 in Logging using a delivery role + bucket
      policy.
   -	GuardDuty: Assumed org-managed in Security (recommended); nothing to create
      in the app account.
-	KMS by default: Logs CMK + EBS default CMK; EBS encryption enabled. Optional
  data CMK.
-	Tagging enforcement: SCP denies creates without Environment, Owner, CostCenter
  (editable).
-	SCP guardrails: deny disabling CloudTrail, deny public S3, require encryption
  on create, restrict regions, protect log KMS key.

### Purpose

-	Centralised logging: tamper-resistant evidence, faster triage, consistent
  detections.
-	KMS everywhere: custody and control of encryption keys; easier attestations;
  safer cross-account flows.
-	Tagging: ownership, cost, and automated governance from day one.
-	SCP guardrails: prevent entire classes of mistakes (public S3, unencrypted
  creates, wrong regions, trail tampering).

### CI/CD and Development Guardrails.

- Open Source MIT License.
- All module calls are locked to a specific version.
- Editorconfig to force a consistent coding style.
- Terraform-Docs automatically (re)generates README documentation.
- A .tool-version for [ASDF](https://asdf-vm.com/) to enforce common tooling
  versions.
- Github Actions to automatically tag and release upon a merge with `main`.
- Tags and Release are immutable across all repos.
- Github Action to run a pre-commit check on a PR. Users would be expected to
  run this themselves before committing by installing it with
  `pre-commit install`
- A Terraform flavoured .gitignore.
- Pre-commit checks for:
    - style enforcement.
    - terraform-docs execution.
    - hard coded secret detection with [Gitleaks](https://gitleaks.io/).
    - generating Terraform documentation.
    - Terraform validation and linting.
    - Using Checkov to scan for security issues.

### Assumptions

- The problem parameters don't mention what regions would be in use. For
  simplicity, I've assumed 1 region - whichever the TF is applied in - but in
  production you'd want a list.  Then you could tighten up policies.

### Checkov Exceptions to fix for Production:

CKV_AWS_144 - Cross Region S3 Replication.

### Future Improvements

- Ideally, all these modules should exist in their own repositories to allow us
  to individually control their versions.
