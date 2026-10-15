# GitHub upload checklist — READ BEFORE COMMITTING

The ZIP provides **documentation, screenshots and an editable architecture diagram only**. It does not contain your `.claude` Skills/Subagents/Hooks source, `.mcp.json`, the website, or actual Terraform `.tf` files; leave those in your existing local repository.

1. **Back up** `README.md`, `docs/`, `screenshots/`, and `diagrams/` before copying the new documentation into the repo.
2. **Inspect the current remote and branch:** `git remote -v && git branch --show-current`.
3. **Confirm no tracked Terraform state or secrets:**

   ```bash
   git ls-files | grep -Ei '(^|/)(\.env($|\.)|\.terraform/|terraform\.tfstate|deploy\.log|.*\.pem$|.*\.key$|backend\.hcl$)'
   ```

4. **Review `.mcp.json` and `.claude/settings.local.json` locally.** Exclude them entirely if they contain API keys, bearer tokens, AWS credentials, or sensitive paths. Do not paste secret values into a chat.
5. **Update `.gitignore`** using the [suggested entries](GITIGNORE_RECOMMENDATIONS.md) that apply to the repository. If a sensitive file was tracked previously, merely adding it to `.gitignore` is insufficient: untrack it, assess Git history, and rotate affected secrets.
6. **Verify staged files before committing:**

   ```bash
   git add README.md docs screenshots diagrams
   git diff --cached --check
   git diff --cached --name-only
   ```

7. Ensure screenshots and Markdown show no credentials or unintended identifiers. Confirm all image links work in GitHub preview.
8. Commit and push **only after the above checks**. Avoid `git add -A` until the whole working tree has been reviewed.

**Suggested GitHub description:**

> Agentic AI DevOps portfolio using Claude Code, Terraform, AWS S3/CloudFront, custom Skills, Subagents, MCP servers, and safety hooks.

**Suggested topics:** `devops`, `agentic-ai`, `claude-code`, `terraform`, `aws`, `mcp`, `infrastructure-as-code`, `devsecops`, `automation`.
