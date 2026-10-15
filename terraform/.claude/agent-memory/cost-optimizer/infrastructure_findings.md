---
name: Cost Optimizer - Infrastructure Findings
description: Detailed cost analysis and optimization opportunities for portfolio site infrastructure
type: project
---

## Infrastructure Composition

### Core Hosting
- **S3 Bucket (site)**: Stores HTML/CSS static files, versioning enabled, KMS encryption
- **S3 Bucket (cf_logs)**: CloudFront access logs, versioning enabled, 90-day expiration
- **CloudFront Distribution**: PriceClass_100 (cheapest tier), 3 rules (Common, BadInputs, RateLimit)
- **WAF WebACL**: 2 managed rule groups + 1 rate-limit rule in us-east-1

### Encryption & State Management
- **KMS Key**: Customer-managed key with automatic annual rotation
- **DynamoDB Table**: State locking (PAY_PER_REQUEST billing, SSE enabled)
- **ACM Certificate**: Optional (only if domain_name is set)

### Configuration Notes
- Region split: ap-south-1 primary, us-east-1 for WAF/ACM/DynamoDB (CloudFront requirement)
- All versioning enabled on S3 buckets
- Both buckets have public access blocked
- CloudFront uses Managed-CachingOptimized policy
- HTTP redirects to HTTPS, IPv6 enabled

## Cost Categories Identified
1. Data transfer (CloudFront, S3 origin requests)
2. Storage (S3 standard, versioning overhead)
3. Logging storage (CF logs, S3 access logs)
4. Security (WAF, KMS key usage, encryption)
5. State management (DynamoDB on-demand, minimal usage)
