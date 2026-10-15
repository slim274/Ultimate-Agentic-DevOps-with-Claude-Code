# /security-audit

**Description:** Analyze the project’s Terraform configuration for potential security risks and misconfigurations.

**Allowed Tools:** Terraform CLI, tfsec, Bash shell

**Model Invocation:** Disabled

**Instructions:**
1. Check that Terraform configuration files exist in the current directory.
2. Run `tfsec .` to scan for security issues.
3. Summarize any warnings and errors found.
4. Provide actionable recommendations to fix high-risk issues.
5. Output a report of the audit results.