---
name: CloudFront recurring security gaps
description: Security issues repeatedly found in CloudFront distributions: weak TLS, missing WAF, missing security headers, no access logging, IPv6 disabled
type: reference
---

As of audit on 2026-03-19 (eighth audit — full re-analysis, no code changes since seventh audit):

RESOLVED in current .tf source (main.tf):
- Security response headers policy configured with CSP, HSTS, X-Frame-Options DENY, referrer policy, content-type-options, xss_protection, and Permissions-Policy. main.tf lines 177-218.
- CloudFront access logging configured to cf-logs bucket. main.tf lines 462-466.
- IPv6 enabled (`is_ipv6_enabled = true`). main.tf line 439.
- WAF WebACL present with AWSManagedRulesCommonRuleSet, AWSManagedRulesKnownBadInputsRuleSet, and a rate-based rule (2000 req/IP), attached to CloudFront via `web_acl_id`. main.tf line 443.
- xss_protection block present.
- OAC is correctly used (not legacy OAI). main.tf lines 166-172, 448.
- HTTP-to-HTTPS redirect is set (`viewer_protocol_policy = "redirect-to-https"`). main.tf line 453.
- S3 bucket public access fully blocked. main.tf lines 57-64.
- S3 bucket encryption is SSE-KMS with customer-managed key (CMK, auto-rotating). main.tf lines 79-161.
- TLS minimum version is `TLSv1.2_2021` (main.tf line 489). Conditional: uses ACM cert when domain_name is set; falls back to cloudfront_default_certificate when no domain is provided (which ignores minimum_protocol_version — TLS fallback still open).
- S3 versioning enabled on both site and cf_logs buckets.
- DynamoDB state lock table encrypted with SSE.
- Lifecycle rule on cf_logs bucket (90-day expiry, 30-day noncurrent).
- S3 server access logging enabled (site bucket → cf_logs bucket).
- Custom 404 returns HTTP 404 (not 200).
- KMS key policy enumerates specific actions (not kms:*). Resource = "*" in a key policy is conventional and correct.

STILL OPEN (confirmed eighth audit 2026-03-19):
1. **Hardcoded account ID in backend.hcl** (HIGH): Account ID `238027390529` embedded in the S3 bucket name on line 3 of backend.hcl. File is gitignored — no commit risk — but bucket name is a permanent artefact. Confirm via `git log -- terraform/backend.hcl`.
2. **TLS fallback when no domain_name set** (MEDIUM): When var.domain_name is empty, `cloudfront_default_certificate = true` is used. AWS ignores minimum_protocol_version for the default CloudFront cert, so TLSv1/TLSv1.1 remain accessible on the *.cloudfront.net domain.
3. **Geo-restriction disabled** (LOW): `restriction_type = "none"` at main.tf line 481. Comment acknowledges intentional.
4. **WAF rate limit of 2000 may be too high** (LOW): Rate-based rule at 2000 req/5 min/IP. For a static portfolio site this is very permissive.
5. **No S3 Object Lock on cf_logs bucket** (LOW): No WORM protection on the audit log bucket.
6. **cf_logs bucket uses BucketOwnerPreferred ownership** (LOW): `object_ownership = "BucketOwnerPreferred"` (main.tf line 248) still allows ACL-based access. `BucketOwnerEnforced` would disable ACLs entirely.
7. **No lifecycle/noncurrent-version expiry on site bucket** (LOW): Versioning enabled but no noncurrent version cleanup rule. Old versions accumulate indefinitely.
8. **KMS S3 service principal unscoped** (LOW): `AllowS3ServiceUsage` statement grants `kms:GenerateDataKey` and `kms:Decrypt` to `s3.amazonaws.com` with `Resource = "*"` but no `aws:SourceAccount` or `aws:SourceArn` condition. Any S3 bucket in AWS could potentially use this key if reachable. Add a Condition: StringEquals aws:SourceAccount to the account ID.
9. **No KMS alias for DynamoDB table** (informational): DynamoDB SSE uses AWS-owned key (no CMK). Low risk for a lock table but worth noting for uniformity.

**How to apply:** Check all these fields whenever reviewing a CloudFront distribution resource in Terraform.
