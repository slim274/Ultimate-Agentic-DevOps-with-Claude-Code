# Security, provenance and limitations

## Reported security review

The Week 9 assignment describes finding and addressing selected AWS KMS policy issues using an agent-assisted audit → fix → validate → re-audit workflow:

- **F-02 — Confused deputy:** Restrict S3 service key use through an `aws:SourceAccount` condition referencing the current AWS account.
- **F-03 — Destructive actions:** Separate destructive KMS permissions and require MFA for those actions.

The report says the user ran `terraform validate` and checked a subsequent auditor report. **This is historical lab documentation; it does not establish that all findings are resolved or that the environment is currently secure.** The report also lists **F-01** concerning `.gitignore` / `backend.hcl` as a follow-up item.

## Handling Terraform state

Do **not** publish:

```text
terraform/.terraform/
terraform/*.tfstate
terraform/*.tfstate.*
terraform/backend.hcl   # if it contains real remote-state or account details
*.tfvars                 # if values contain secrets
.env
.env.*
*.pem
*.key
.claude/deploy.log
.claude/settings.local.json  # review before sharing
.mcp.json                 # review before sharing, may contain local paths or credentials
```

Terraform state may contain resource metadata or secret outputs even when `.tf` files look harmless. **Ignoring a file now does not delete a copy already stored in Git history.** If sensitive content was pushed, revoke or rotate exposed secrets and review repository history.

## Security guardrails

- Restrict IAM to permissions actually required; the lab included a broad IAM inline policy to diagnose access errors.
- Require explicit approval for mutating agent tools and infrastructure changes.
- Keep provider credentials out of README files, screenshots, and configuration templates.
- Treat hook filters as additional controls, not a substitute for cloud IAM boundaries.
- Confirm state-backend locking and encryption rather than assuming a written setup provides them.
- Inspect screenshots at full resolution before publicly publishing them.

## Reuse caveat

The recorded workflow was a **training exercise**. Cost estimates and security findings are documented agent outputs, not independently validated production performance or compliance statements.
