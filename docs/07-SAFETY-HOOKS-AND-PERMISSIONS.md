# 07 — Safety hooks, permissions and action logging

[← Project README](../README.md) · [← MCP](06-MCP-SERVER-INTEGRATION.md)

**Week 9, Assignment 7.** Hooks are configurable checkpoints around Claude Code activity. The Week 9 report organizes the exercise as **SAY / DO / LOG**.

## Implemented scripts and responsibilities

| Safety stage | Existing local file | Role in the recorded lab |
|---|---|---|
| **SAY** — prompt input | `.claude/hooks/user-prompt-guard.sh` | Examine and potentially reject destructive user requests. |
| **DO** — tool execution | `.claude/hooks/pre-tool-guard.sh` | Inspect planned tool/Bash commands before execution. |
| **LOG** — post-tool | `.claude/hooks/post-tool-logger.sh` | Append selected action details to a local deployment log. |

The report describes creating `.claude/hooks/`, making scripts executable, and wiring them into local Claude Code hook settings. The relevant local settings file must be reviewed before publication.

## What was tested

- A destructive prompt such as **“delete all resources”** was blocked by the prompt guard during the demo.
- A request involving **`terraform destroy`** was rejected by the pre-tool guard.
- The user discovered that running Terraform **directly in a local terminal** does not trigger Claude Code hooks. Tests needed to be invoked through Claude's tool workflow.
- A logged Terraform action wrote a timestamped entry to `.claude/deploy.log` after the script's output path was corrected.

## Troubleshooting from the report

| Issue | Resolution documented |
|---|---|
| Settings JSON had the wrong hook structure | Reworked the hook configuration into the required arrays/objects. |
| Hook shell scripts could not run as intended | Checked `chmod +x` permissions. |
| Claude and MCP interaction complicated hook testing | Temporarily adjusted the local test configuration. |
| A relative log path did not create the expected file | Changed to an absolute path. |
| A guard blocked the lab's permitted Terraform apply path | Adjusted the rule and retested the intended scenario. |

## Security limits

**Hooks are supplementary guardrails, not a sandbox or an AWS authorization boundary.** A pattern match may miss reworded requests, and its behavior depends on Claude Code's current events, settings, and tool invocation path. Restrict permissions, require human approval for cloud modifications, and test controls after upgrades.

Do not publish `.claude/deploy.log` or unreviewed `.claude/settings.local.json`; both may include local metadata.

## Screenshots

| Hook config | Blocked / tested command |
|:--:|:--:|
| [![Hook configuration](../screenshots/15-hook-configuration.png)](../screenshots/15-hook-configuration.png) | [![Hook execution](../screenshots/16-hook-execution.png)](../screenshots/16-hook-execution.png) |

| Action logging | Test evidence |
|:--:|:--:|
| [![Deploy logging](../screenshots/17-deployment-logging.png)](../screenshots/17-deployment-logging.png) | [![Hook tests](../screenshots/18-hook-test-evidence.png)](../screenshots/18-hook-test-evidence.png) |

Source: original Week 9 Word report, **Assignment 7**. [Evidence index](../screenshots/README.md).
