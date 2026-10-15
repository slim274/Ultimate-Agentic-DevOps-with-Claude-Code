---
name: project_infra
description: Architecture summary for the Terraform-managed CloudFront + S3 static site as of the 2026-03-19 audit v3
type: project
---

Static site hosting stack (current state as of 2026-03-19 v3):
- S3 bucket (`aws_s3_bucket.site`) — private, versioned, SSE-KMS with CMK, public access fully blocked, prevent_destroy enabled
- S3 log bucket (`aws_s3_bucket.cf_logs`) — private, versioned, SSE-KMS (same CMK), 90-day lifecycle, prevent_destroy enabled
- Customer-managed KMS key (`aws_kms_key.s3`) — encrypts both S3 buckets; enable_key_rotation=true; 30-day deletion window; NO prevent_destroy (open finding F-07)
- CloudFront distribution with OAC (not legacy OAI), HTTP-to-HTTPS redirect, WAF attached, security response headers policy, TLSv1.2_2021 unconditional
- WAFv2 WebACL in us-east-1 with AWSManagedRulesCommonRuleSet, AWSManagedRulesKnownBadInputsRuleSet, and IP rate-limiting (2000 req/IP)
- Security response headers: HSTS (1yr, includeSubDomains, preload), CSP (self + cdnjs.cloudflare.com), X-Frame-Options DENY, X-Content-Type-Options, Referrer-Policy, XSS protection, Permissions-Policy
- Remote state in S3 (bucket name in gitignored backend.hcl), encrypt=true; use_lockfile=true (INVALID attribute — DynamoDB locking may be disabled, see F-04)
- DynamoDB lock table provisioned in main.tf (`portfolio-site-tfstate-lock`, PAY_PER_REQUEST, SSE enabled, prevent_destroy)
- ACM certificate with DNS validation; TLSv1.2_2021 minimum (now unconditional)
- No OIDC / GitHub Actions IAM role in this codebase
- Deployment region: ap-south-1 (var.region default); state bucket and WAF/ACM in us-east-1 (intentional split, poorly documented)

Open findings (v3):
- F-01 CRITICAL: .gitignore never committed — backend.hcl unprotected
- F-02 HIGH: KMS S3 service principal lacks aws:SourceArn condition
- F-03 HIGH: KMS root statement over-privileged (includes PutKeyPolicy, ScheduleKeyDeletion, DisableKey)
- F-04 MEDIUM: backend.tf uses use_lockfile=true (invalid); missing dynamodb_table
- F-05 MEDIUM: domain_name variable has no validation
- F-06 MEDIUM: undocumented region split; duplicate region attribute
- F-07 MEDIUM: no prevent_destroy on aws_kms_key.s3
- F-08 LOW: .terraform.lock.hcl gitignored (should be committed)
- F-09 LOW: S3 access logs co-mingled in CF log bucket; 90-day expiry applies to all
- F-10 LOW: no geo-restriction (intentional)

**Why:** Understanding the full architecture helps scope future change reviews correctly.
**How to apply:** When suggesting changes, respect the OAC + private-S3 + KMS-CMK pattern. Do not introduce anything that opens the bucket to direct public access. Remind user that `backend.hcl` must be created locally before `terraform init`. The most urgent fix is committing .gitignore before staging any terraform files.
