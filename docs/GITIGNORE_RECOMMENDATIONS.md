# Suggested `.gitignore` entries

Review before merging with your repository's existing `.gitignore`; do **not** overwrite existing rules blindly.

```gitignore
# Secrets and local environment
.env
.env.*
!.env.example
*.pem
*.key
*credentials*

# Terraform local and sensitive state
**/.terraform/
*.tfstate
*.tfstate.*
crash.log
crash.*.log
*.tfvars
*.tfvars.json
terraform/backend.hcl

# Local agent configuration / logs (review for safe public templates separately)
.claude/settings.local.json
.claude/deploy.log
.mcp.json

# Editor and system
.DS_Store
.vscode/settings.json
```

Some projects intentionally share safe `.tfvars.example` files or sanitized MCP templates; those can be reviewed and committed separately. Never publish the original sensitive values.
