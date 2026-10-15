# Cost Optimizer Memory Index

## Infrastructure Overview
- **project_type**: Static portfolio website (HTML/CSS) for DevOps micro internship
- **hosting_pattern**: S3 + CloudFront + WAF + KMS + DynamoDB
- **region**: Primary ap-south-1, secondary us-east-1 (WAF/ACM/DynamoDB)
- **current_monthly_cost**: $15.01
- **optimization_potential**: $8.47/month (56% reduction)

## Memory Files
1. **infrastructure_findings.md** - Detailed resource inventory and cost drivers
2. **optimization_recommendations.md** - Specific changes with impact analysis

## Key Numbers
- Baseline: $15.01/month
- After Phase 1 (no WAF): $8.21/month
- After Phase 2 (no KMS): $7.21/month
- After Phase 3 (30-day logs): $6.54/month
- **Total savings potential: $8.47/month ($101.60/year)**

## Biggest Cost Drivers
1. WAF: $6.80/month (45% of total) — RECOMMENDED TO DISABLE
2. CloudFront: $4.25/month (28%) — Already optimized (PriceClass_100)
3. S3 Logs: $2.50/month (17%) — Can reduce retention to 30 days
4. KMS: $1.00/month (7%) — Switch to AWS-managed KMS

## Low-Risk Changes (Apply First)
- Disable WAF (static site doesn't need it)
- Switch to AWS-managed KMS (saves $1/month, no functional loss)
- Reduce log retention 90→30 days (still industry-standard)

## Reports Generated
- `/terraform/COST_OPTIMIZATION_REPORT.md` - 300-line detailed analysis
- `/terraform/COST_QUICK_REFERENCE.md` - One-page executive summary
- `/terraform/OPTIMIZATION_PATCHES.md` - Ready-to-apply code changes by phase
