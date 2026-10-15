# Terraform Optimization Patches

This document contains ready-to-apply code changes for cost optimization. Apply patches in order (Phase 1 → Phase 2 → Phase 3).

---

## PHASE 1: Remove WAF (Save $6.80/month)

### Changes to `variables.tf`

Add new variable at end of file:
```hcl
variable "enable_waf" {
  description = "Enable AWS WAF for CloudFront distribution (adds ~$7/month cost)"
  type        = bool
  default     = false
}
```

### Changes to `main.tf`

#### Update `aws_wafv2_web_acl` (line 249)

FROM:
```hcl
resource "aws_wafv2_web_acl" "site" {
  provider    = aws.us_east_1
  name        = "${var.project_name}-${var.environment}-waf"
  # ... rest of resource
```

TO:
```hcl
resource "aws_wafv2_web_acl" "site" {
  count       = var.enable_waf ? 1 : 0
  provider    = aws.us_east_1
  name        = "${var.project_name}-${var.environment}-waf"
  # ... rest of resource unchanged
```

#### Update `aws_cloudfront_distribution` (line 388)

FROM:
```hcl
  web_acl_id = aws_wafv2_web_acl.site.arn
```

TO:
```hcl
  web_acl_id = var.enable_waf ? aws_wafv2_web_acl.site[0].arn : null
```

### Deployment

```bash
cd /home/slim/Ultimate-Agentic-DevOps-with-Claude-Code/terraform

# Verify changes
terraform plan -var="enable_waf=false"

# Apply
terraform apply -var="enable_waf=false"
```

### Cost Impact
- **Savings**: $6.80/month ($81.60/year)
- **New monthly total**: $8.21

---

## PHASE 2: Switch to AWS-Managed KMS (Save $1.00/month)

### Changes to `main.tf`

#### Remove KMS Key Resource (lines 77-91)

DELETE these entire resource blocks:
```hcl
resource "aws_kms_key" "s3" {
  description             = "CMK for ${var.project_name} S3 buckets"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${var.project_name}-${var.environment}-s3"
  target_key_id = aws_kms_key.s3.key_id
}
```

#### Update Site Bucket Encryption (lines 96-106)

FROM:
```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
    bucket_key_enabled = true
  }
}
```

TO:
```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}
```

#### Update CloudFront Logs Bucket Encryption (lines 197-207)

FROM:
```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
    bucket_key_enabled = true
  }
}
```

TO:
```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}
```

### Deployment

```bash
cd /home/slim/Ultimate-Agentic-DevOps-with-Claude-Code/terraform

# Verify changes
terraform plan -var="enable_waf=false"

# Check for KMS key destruction in plan output
# WARNING: This will destroy the customer-managed key
# AWS-managed encryption takes over automatically

# Apply (will destroy old key and reencrypt with AWS-managed key)
terraform apply -var="enable_waf=false"
```

### Cost Impact
- **Savings**: $1.00/month ($12.00/year)
- **New monthly total**: $7.21

### Notes
- Terraform will detect encryption change and trigger reencryption
- Reencryption is transparent; no downtime
- Data remains encrypted at rest with same strength
- Lose: Audit trail of key usage, individual key rotation control
- Gain: $1/month savings, simplified key management

---

## PHASE 3: Reduce CloudFront Log Retention (Save $0.67/month)

### Changes to `main.tf`

#### Update CloudFront Logs Lifecycle (lines 217-234)

FROM:
```hcl
resource "aws_s3_bucket_lifecycle_configuration" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id

  rule {
    id     = "expire-cf-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}
```

TO:
```hcl
resource "aws_s3_bucket_lifecycle_configuration" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id

  rule {
    id     = "expire-cf-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}
```

### Deployment

```bash
cd /home/slim/Ultimate-Agentic-DevOps-with-Claude-Code/terraform

# Verify changes
terraform plan -var="enable_waf=false"

# Should show lifecycle configuration change only
# Apply
terraform apply -var="enable_waf=false"
```

### Cost Impact
- **Savings**: $0.67/month ($8.04/year)
- **New monthly total**: $6.54

### Impact Analysis
- **Positive**: 30 days is still industry-standard for log retention
- **Positive**: Saves 2/3 of log storage costs
- **Consideration**: Reduced historical window for debugging
- **Mitigation**: Enable CloudWatch alarms for metrics; keep git history of deployments

---

## OPTIONAL: Additional Low-Impact Changes

### Option A: Disable S3 Versioning (Save ~$0.30/month)

#### Update S3 Site Bucket Versioning (lines 66-72)

DELETE:
```hcl
resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id

  versioning_configuration {
    status = "Enabled"
  }
}
```

OR REPLACE WITH:
```hcl
resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id

  versioning_configuration {
    status = "Suspended"  # Keep bucket, disable new versions
  }
}
```

**Risk**: Medium | **Savings**: $0.30/month

**Recommendation**: Only if you have strong deployment/backup process using Git.

---

### Option B: Disable S3 Access Logging (Save ~$0.05/month)

#### Remove S3 Access Logging (lines 239-243)

DELETE:
```hcl
resource "aws_s3_bucket_logging" "site" {
  bucket        = aws_s3_bucket.site.id
  target_bucket = aws_s3_bucket.cf_logs.id
  target_prefix = "s3-access-logs/"
}
```

**Risk**: Low | **Savings**: $0.05/month

**Reason**: CloudFront logs are more comprehensive; S3 access logs are redundant.

---

### Option C: Use Intelligent-Tiering for Logs (Save ~$0.30/month, Keep 90-day History)

#### Add Intelligent-Tiering Lifecycle (replace expiration rule)

REPLACE:
```hcl
resource "aws_s3_bucket_lifecycle_configuration" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id

  rule {
    id     = "expire-cf-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}
```

WITH:
```hcl
resource "aws_s3_bucket_lifecycle_configuration" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id

  rule {
    id     = "tier-cf-logs"
    status = "Enabled"

    filter {}

    transition {
      days          = 1
      storage_class = "INTELLIGENT_TIERING"
    }

    expiration {
      days = 90
    }

    noncurrent_version_transition {
      noncurrent_days          = 1
      storage_class            = "INTELLIGENT_TIERING"
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}
```

**Benefit**: Logs stay in Standard for 1 day (hot), then S3 automatically tiers to Archive if unused (cheaper)

**Cost**: ~$0.30/month savings + per-retrieval cost if you access old logs

**Recommendation**: Good middle ground if you want history but can't afford pure Standard storage.

---

## Full Apply Command (All Phases)

After applying all patches:

```bash
cd /home/slim/Ultimate-Agentic-DevOps-with-Claude-Code/terraform

# Final validation
terraform plan -var="enable_waf=false"

# Review output carefully — should show:
# - 1 variable added (enable_waf)
# - 2 resources removed (KMS key + alias)
# - 2 resources modified (encryption configs)
# - 1 resource modified (CloudFront distribution)
# - 1 resource modified (lifecycle config)

# Deploy
terraform apply -var="enable_waf=false"

# Verify
terraform show | grep -E "(encryption|waf|lifecycle)"
```

---

## Rollback Plan

If you need to revert:

```bash
# Option 1: Enable WAF again
terraform apply -var="enable_waf=true"

# Option 2: Full rollback (revert to main branch + reapply original)
git checkout HEAD -- main.tf variables.tf
terraform apply

# Option 3: Restore KMS key from AWS Backup Vault (if using AWS Backup)
# Manual: Recreate the KMS key and update S3 bucket encryption
```

---

## Verification Checklist

After applying all patches:

- [ ] CloudFront distribution still accessible
- [ ] S3 bucket still private (public access blocked)
- [ ] Files still served via CloudFront (test with curl/browser)
- [ ] S3 encryption still working (check bucket properties)
- [ ] CloudWatch metrics show no errors
- [ ] Terraform state valid (`terraform validate`)

### Test Commands

```bash
# Get distribution domain
DIST_ID=$(terraform output -raw cloudfront_distribution_id)
DOMAIN=$(terraform output -raw cloudfront_domain_name)

# Test HTTP→HTTPS redirect
curl -I http://$DOMAIN/

# Test HTTPS access
curl -I https://$DOMAIN/

# Check cache hit rate (should be >95%)
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name CacheHitRate \
  --dimensions Name=DistributionId,Value=$DIST_ID \
  --start-time 2026-03-10T00:00:00Z \
  --end-time 2026-03-17T23:59:59Z \
  --period 86400 \
  --statistics Average
```

---

## Summary

| Phase | Change | Monthly Savings | Cumulative |
|-------|--------|---|---|
| 1 | Disable WAF | $6.80 | $6.80 |
| 2 | AWS-Managed KMS | $1.00 | $7.80 |
| 3 | Reduce log retention | $0.67 | $8.47 |
| **Total** | — | — | **$8.47/month** |

**Before**: $15.01/month | **After**: $6.54/month | **Savings**: 56%

---

## Support & Questions

- Terraform docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- AWS pricing calculator: https://calculator.aws/
- CloudFront caching: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Expiration.html
- S3 pricing: https://aws.amazon.com/s3/pricing/
