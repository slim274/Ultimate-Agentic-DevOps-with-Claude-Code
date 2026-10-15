---
name: Portfolio Site Cost Analysis
description: Cost optimization findings for static portfolio site infrastructure
type: project
---

## Infrastructure Summary
- **Project**: portfolio-site-abiodun (production)
- **Region**: ap-south-1 (Asia Pacific Mumbai)
- **Primary Resources**: S3 bucket + CloudFront distribution
- **Use Case**: Static HTML/CSS website (lightweight portfolio)

## Key Findings
1. S3 versioning enabled but no lifecycle rules → unnecessary storage growth
2. CloudFront using PriceClass_200 (moderate cost) when PriceClass_100 would suffice for low-traffic portfolio
3. S3 bucket in ap-south-1 with CloudFront → potential for regional optimization
4. Default CachingOptimized policy adequate but could extend TTLs for static assets
5. Small static website (HTML/CSS/images only) does not need aggressive data transfer patterns

## Cost Drivers Identified
- S3 storage costs growing due to versioning without cleanup
- CloudFront edge locations (PriceClass_200 covers North America/Europe/Asia/Australia)
- S3 API request costs from CloudFront origin
