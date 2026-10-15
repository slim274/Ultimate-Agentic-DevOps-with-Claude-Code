# Cost Optimization Quick Reference

## Current Monthly Cost Estimate: $15.01

| Service | Cost | % |
|---------|------|---|
| WAF | $6.80 | 45% |
| CloudFront | $4.25 | 28% |
| S3 Logs | $2.50 | 17% |
| KMS | $1.00 | 7% |
| S3 Site | $0.10 | 1% |
| DynamoDB | $0.36 | 2% |

---

## Top 3 Recommendations (in priority order)

### 1. Disable WAF → Save $6.80/month
**Risk**: LOW | **Effort**: 15 min | **Impact**: HIGH

Static portfolios don't need WAF. CloudFront + S3 bucket policies + CSP headers provide sufficient protection.

**Change**: Set `web_acl_id = null` in CloudFront distribution OR make WAF optional with a variable.

```hcl
variable "enable_waf" {
  default = false
}
resource "aws_wafv2_web_acl" "site" {
  count = var.enable_waf ? 1 : 0
  # ...
}
```

---

### 2. Switch to AWS-Managed KMS → Save $1.00/month
**Risk**: LOW | **Effort**: 10 min | **Impact**: MEDIUM

No functional difference for static sites. Lose audit trail (acceptable tradeoff).

**Change**: Remove `aws_kms_key` and `aws_kms_alias` resources. Update S3 encryption to use default AWS-managed key:

```hcl
apply_server_side_encryption_by_default {
  sse_algorithm = "aws:kms"
  # Remove kms_master_key_id line
}
```

---

### 3. Reduce CloudFront Log Retention → Save $0.67/month
**Risk**: LOW | **Effort**: 5 min | **Impact**: LOW

Change log expiration from 90 days to 30 days (still industry-standard for troubleshooting).

**Change**: Update lifecycle rule:
```hcl
expiration {
  days = 30  # was 90
}
```

---

## Combined Savings

| Phase | Total Cost | Monthly Savings | Annual Savings |
|-------|-----------|---|---|
| Current | $15.01 | — | — |
| After #1 (no WAF) | $8.21 | $6.80 | $81.60 |
| After #2 (no KMS) | $7.21 | $7.80 | $93.60 |
| After #3 (30-day logs) | $6.54 | $8.47 | $101.60 |

**Total potential savings: $8.47/month (56% reduction)**

---

## Implementation Checklist

- [ ] Add `enable_waf` variable to `variables.tf` (default: false)
- [ ] Update `aws_wafv2_web_acl` to use `count` (conditional)
- [ ] Update CloudFront `web_acl_id` to use conditional
- [ ] Remove `aws_kms_key` resource
- [ ] Remove `aws_kms_alias` resource
- [ ] Update S3 encryption configs to remove `kms_master_key_id`
- [ ] Reduce CloudFront log expiration from 90 → 30 days
- [ ] Run `terraform plan` and review
- [ ] Run `terraform apply`

---

## What NOT to Change

✓ Keep CloudFront Price Class at `PriceClass_100` (already optimal)
✓ Keep S3 public access blocked (security best practice)
✓ Keep HTTPS redirect (security best practice)
✓ Keep Managed-CachingOptimized cache policy (good defaults)
✓ Keep response headers + CSP policies (security best practice)

---

## Additional Low-Impact Options

**Disable S3 versioning** (if comfortable with manual backups): -$0.30/mo
- Risk: No rollback without Git history
- Recommendation: Keep unless you have solid deployment process

**Disable S3 access logging** (redundant with CloudFront logs): -$0.05/mo
- Risk: Minimal; CloudFront logs are more comprehensive
- Recommendation: Safe to disable

---

## When to Re-enable WAF

Re-enable WAF if any of these occur:
- You add interactive features (forms, APIs)
- Traffic increases dramatically (>10x)
- You observe attack patterns (SQL injection, XSS attempts)
- You need compliance/regulatory requirements (PCI-DSS, HIPAA, etc.)

---

## Files Modified

See detailed recommendations in: `/home/slim/Ultimate-Agentic-DevOps-with-Claude-Code/terraform/COST_OPTIMIZATION_REPORT.md`

All line numbers and code snippets provided for exact changes.

---

## Questions?

Estimated breakdown by service assumes:
- 200k CloudFront requests/month (varies with traffic)
- Primarily US/EU audience (PriceClass_100 covers)
- 100GB CF logs/month
- Minimal S3 API calls (good caching)

Adjust estimates if your traffic profile differs.
