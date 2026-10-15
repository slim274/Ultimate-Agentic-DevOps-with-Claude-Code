---
name: patterns_good
description: Security patterns that are correctly implemented in this codebase — use as a baseline when reviewing future changes
type: reference
---

Patterns confirmed well-implemented as of 2026-03-19 audit v3:

1. S3 public access block — all four flags (`block_public_acls`, `block_public_policy`, `ignore_public_acls`, `restrict_public_buckets`) set to true on both the site bucket and the log bucket.
2. CloudFront OAC (not legacy OAI) — `aws_cloudfront_origin_access_control` with sigv4 signing; bucket policy scoped to specific distribution ARN via `AWS:SourceArn` condition.
3. HTTP-to-HTTPS redirect — `viewer_protocol_policy = "redirect-to-https"`.
4. TLS minimum TLSv1.2_2021 — now enforced unconditionally on both default and custom domain code paths (not conditional on var.domain_name).
5. SSE-KMS with CMK — both site and log S3 buckets use `sse_algorithm = "aws:kms"` with `aws_kms_key.s3`; `bucket_key_enabled = true` to reduce KMS API costs.
6. KMS key rotation — `enable_key_rotation = true`; 30-day deletion window.
7. Security response headers — HSTS (1yr, includeSubDomains, preload), CSP scoped to self + cdnjs.cloudflare.com, X-Frame-Options DENY, X-Content-Type-Options, Referrer-Policy strict-origin-when-cross-origin, XSS protection, Permissions-Policy.
8. WAF attached to CloudFront — AWSManagedRulesCommonRuleSet, AWSManagedRulesKnownBadInputsRuleSet, IP rate-limit 2000 req/IP.
9. State file encryption — `encrypt = true` in backend.tf.
10. DynamoDB lock table has `server_side_encryption { enabled = true }` and `lifecycle { prevent_destroy = true }`.
11. S3 versioning enabled on both site and log buckets.
12. CF access logging to a separate encrypted, lifecycle-managed (90-day expiry) bucket.
13. No hardcoded credentials, secret keys, or AWS account IDs in any .tf file.
14. IAM bucket policy uses least-privilege: only `s3:GetObject`, scoped to `bucket_arn/*`, conditioned on specific CloudFront distribution ARN.
15. `.gitignore` correctly excludes `*.tfstate`, `*.tfstate.backup`, `.terraform/`, `*.tfvars`, `backend.hcl`. However: .gitignore is itself untracked (CRITICAL — see F-01).
16. Backend bucket name externalized to gitignored `backend.hcl`.
17. All three primary variables (region, project_name, environment) have validation blocks.
18. `prevent_destroy = true` on site bucket, log bucket, DynamoDB lock table.
19. CloudFront managed cache policy referenced by name via data source (not hardcoded UUID).
20. ACM certificate uses DNS validation.
21. `s3_bucket_name` and `s3_bucket_arn` outputs both marked `sensitive = true`.
22. KMS alias created for human-readable key identification.
23. `data "aws_caller_identity"` used to avoid hardcoding account ID in KMS policy.
