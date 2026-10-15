# Troubleshooting recorded during Week 9

| Issue | Reported resolution / learning |
|---|---|
| Claude CLI global install returned `EACCES` | Completed installation with elevated permissions during the lab; a user-managed installation path is preferable in other setups. |
| Terraform apply failed with AWS IAM errors | Added lab IAM permissions for S3 and CloudFront and retried. The example policy was broad, so tighten for production. |
| S3 `BucketAlreadyExists` | Changed to a globally unique bucket name before reapplying. |
| MCP command reported no servers | Moved `.mcp.json` to the project root, updated the local Docker mount, and restarted Claude. |
| Security audit found KMS policy issues | Adjusted `aws:SourceAccount` and MFA conditions; ran Terraform validation and a follow-up review. |
| Hook configuration was rejected | Reworked JSON hook structure and script executability. |
| Logger did not create `deploy.log` | Used an absolute path for the log destination. |
| Running Terraform directly did not activate Claude hooks | Ran the test through Claude's Bash tool instead. |
| Pre-tool guard blocked a permitted apply test | Adjusted the lab guard to allow a reviewed, non-`-auto-approve` apply path. |

These outcomes come from the student's Week 9 report. They are not a substitute for testing the current CLI, Terraform provider, AWS account, and policies.
