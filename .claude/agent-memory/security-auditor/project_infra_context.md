---
name: portfolio site infrastructure context
description: AWS infrastructure for portfolio-site project — S3 + CloudFront stack, region ap-south-1
type: project
---

Stack is a static website hosted on S3 served via CloudFront (OAC pattern). Resources live in ap-south-1. Terraform files: main.tf, variables.tf, outputs.tf, providers.tf, backend.tf. Eighth audit completed 2026-03-19.

Account ID `238027390529` is exposed in `terraform/backend.hcl` (line 3: bucket name contains account ID). backend.hcl is gitignored.

backend.tf uses a remote S3 backend configured via `-backend-config=backend.hcl`. terraform.tfstate is empty (1 line). terraform.tfstate.backup is NO LONGER ON DISK as of sixth audit (2026-03-19) — previously present, now deleted.

.gitignore exists at repo root covering terraform/*.tfstate, *.tfstate.backup, backend.hcl, *.tfvars, .terraform/, .terraform.lock.hcl.

**Why:** backend.hcl was intentionally gitignored by design; .gitignore is now in place. tfstate.backup removal is a positive change.

**How to apply:** Always verify .gitignore covers state files. Confirm tfstate.backup was never committed via `git log -- terraform/terraform.tfstate.backup`. Treat account ID 238027390529 as potentially public until history is confirmed clean.
