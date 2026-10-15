---
name: tfstate committed to repo — data exposure pattern
description: Pattern where terraform.tfstate and .tfstate.backup are committed, leaking account IDs, ARNs, and live resource identifiers
type: reference
---

Committed tfstate files expose: AWS account IDs, CloudFront distribution IDs, OAC IDs, bucket ARNs, and canonical user IDs.

Fix pattern:
1. Add `terraform.tfstate` and `terraform.tfstate.backup` to `.gitignore` immediately.
2. Enable the remote S3 backend (backend.tf is already scaffolded in this project but commented out).
3. Run `git rm --cached terraform/terraform.tfstate terraform/terraform.tfstate.backup` and rotate any exposed credentials/IDs if the repo is public.

**How to apply:** Flag this as CRITICAL in any audit where tfstate is present in the repo tree.
