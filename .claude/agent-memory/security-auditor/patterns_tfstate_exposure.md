---
name: tfstate exposure pattern
description: Pattern: tfstate files and backend config committed to repo expose real AWS account IDs and resource ARNs — confirmed in this codebase
type: reference
---

As of 2026-03-19 audit (seventh audit):

- `terraform/terraform.tfstate` — empty (1 line), remote backend in use.
- `terraform/terraform.tfstate.backup` — NO LONGER ON DISK as of sixth audit. Previously (through fifth audit) contained serial 52 with account ID `238027390529`, CloudFront distribution ID `E2XTLQWWRNON6T`, domain `d2onm2ymawqzgb.cloudfront.net`, and S3 ARN `arn:aws:s3:::portfolio-site-abiodun-production-site`. File has now been deleted from disk.
- `terraform/backend.hcl` — still present on disk, gitignored. Contains bucket name `portfolio-site-tfstate-238027390529` which embeds the account ID.

.gitignore at repo root covers all state files — C-1 is fully resolved.

Remediation priority order:
1. (DONE) .gitignore created.
2. Run `git log -- terraform/terraform.tfstate.backup` and `git log -- terraform/backend.hcl` — if either shows prior commits, purge with `git filter-repo` and rotate account credentials.
3. Treat account ID `238027390529` as potentially public until history is confirmed clean.
4. Consider renaming the tfstate S3 bucket to remove the account ID from the name (use a project-slug name instead).

**How to apply:** Always check .gitignore existence and backend.hcl presence whenever reviewing this project. tfstate.backup on disk without gitignore protection is the highest-priority finding.
