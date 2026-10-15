---
name: patterns_findings
description: Security findings cross-referenced against 2026-03-19 audit v3, updated post re-audit same date
type: reference
---

Findings as of 2026-03-19 re-audit. F-02 and F-03 from v3 are now RESOLVED.
8 findings remain OPEN (F-01, F-04 through F-10).

## RESOLVED FINDINGS (confirmed absent in code)

- F-01 (v2): Hardcoded AWS account ID in backend.tf — bucket name in gitignored backend.hcl. RESOLVED.
- F-02 (v2): No DynamoDB state locking — `dynamodb_table` present. RESOLVED (but see F-04 below re: use_lockfile).
- F-03 (v2): TLS 1.0 on default cert path — `minimum_protocol_version = "TLSv1.2_2021"` unconditional. RESOLVED.
- F-05 (v2): No variable validation — all three primary variables validated. RESOLVED.
- F-06 (v2): .gitignore missing tfvars — present in root .gitignore. RESOLVED.
- F-07 (v2): Hardcoded cache policy UUID — uses data source. RESOLVED.
- F-08 (v2): SSE-S3 only — both buckets now use SSE-KMS with CMK. RESOLVED.
- F-09 (v2): No prevent_destroy on site bucket — present. RESOLVED.
- F-10 (v2): No DynamoDB SSE — `server_side_encryption { enabled = true }` present. RESOLVED.
- F-11 (v2): No prevent_destroy on log bucket / DynamoDB table — both now have it. RESOLVED.
- F-02 (v3): KMS AllowS3ServiceUsage — `aws:SourceAccount` condition now present (main.tf lines 151-155). RESOLVED.
- F-03 (v3): KMS root destructive actions — separated into `KMSAdminDestructive` statement with `aws:MultiFactorAuthPresent = true` condition (main.tf lines 119-138). RESOLVED.

## OPEN FINDINGS (v3, post re-audit)

### F-01: .gitignore never committed — backend.hcl has no protection (CRITICAL)
- File: .gitignore (root), backend.hcl
- .gitignore is untracked (`?? .gitignore` in git status). An untracked .gitignore provides zero protection. `git add .` will commit backend.hcl which contains the state bucket name.
- Fix: Commit .gitignore first, verify `git check-ignore -v terraform/backend.hcl`, then stage other files.

### F-04: backend.tf uses use_lockfile=true — not a valid S3 backend parameter; dynamodb_table missing (MEDIUM)
- File: backend.tf line 17
- `use_lockfile` is not a recognized Terraform S3 backend attribute. No `dynamodb_table` is set. State locking is likely silently disabled despite DynamoDB table being provisioned.
- Fix: Replace `use_lockfile = true` with `dynamodb_table = "portfolio-site-tfstate-lock"`.

### F-05: domain_name variable has no validation block (MEDIUM)
- File: variables.tf lines 34-38
- All three other variables have validation; domain_name does not. Malformed input (spaces, http:// prefix) produces a confusing provider error.
- Fix: Add regex validation: `can(regex("^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\\.)+[a-z]{2,}$", var.domain_name))` when non-empty.

### F-06: Undocumented intentional region split between backend.tf and var.region (MEDIUM)
- File: backend.tf line 15, backend.hcl line 2
- State bucket hardcoded to us-east-1; deployment region defaults to ap-south-1. No comment explaining split. Duplicate `region` in both backend.tf and backend.hcl.
- Fix: Add explanatory comment in backend.tf; remove duplicate region from backend.hcl.

### F-07: No prevent_destroy on aws_kms_key.s3 (MEDIUM)
- File: main.tf lines 79-141
- CMK encrypts both site and log S3 buckets. Destruction makes all encrypted data permanently inaccessible (only 7-day deletion window as safety net).
- Fix: Add `lifecycle { prevent_destroy = true }` to `aws_kms_key.s3`.

### F-08: .terraform.lock.hcl gitignored against Terraform best practice (LOW)
- File: .gitignore line 7
- Lock file pins provider checksums for supply chain integrity. Gitignoring it means every init re-resolves versions without checksum baseline.
- Fix: Remove from .gitignore; commit the lock file.

### F-09: S3 access logs co-mingled in CF log bucket with blanket 90-day expiry (LOW)
- File: main.tf lines 272-289, 294-298
- `aws_s3_bucket_logging.site` routes S3 API logs to cf_logs bucket. Lifecycle rule expires all objects at 90 days with no prefix filter — S3 access logs expire at same rate as CF logs.
- Fix: Add a separate lifecycle rule scoped to `s3-access-logs/` prefix with longer retention (e.g., 365 days).

### F-10: No geo-restriction — intentional (LOW)
- File: main.tf lines 475-483
- `restriction_type = "none"` — acknowledged in code comment as intentional for global portfolio audience. Acceptable.
