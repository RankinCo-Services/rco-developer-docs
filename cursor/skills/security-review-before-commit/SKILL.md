---
name: security-review-before-commit
description: Run the security-compliance subagent on code changes before commit and interpret the compliance report. Use when the user asks for a security review before commit or when preparing to commit code.
---

# Security review before commit

## When to use

- User asks to "run security review on my changes" or "check security before commit."
- Agent is about to recommend committing; run the security subagent first.

## Steps

1. Get the current code changes (e.g. `git diff` for unstaged, `git diff --staged` for staged).
2. Launch the **security-compliance** subagent with the diff and request a compliance report.
3. Wait for the subagent’s report (foreground).
4. Interpret the report:
   - **PASS:** Safe to recommend commit; optionally summarize.
   - **FAIL:** Do not recommend commit. List violations and remediation; offer to fix or note user-approved exceptions.

## Output to user

Summarize the subagent result: pass/fail, number of findings, and either "OK to commit" or the list of issues to fix.
