# Security rules (RCO Developer Documents)

Canonical list of security rules used by the security-compliance subagent. Edit this file to add or change rules; then re-copy this repo’s `cursor/` config into projects that use it.

## Placeholder

Starter rules will be added here. The security-compliance agent also applies baseline rules (no hardcoded secrets, input validation, auth, sensitive data, dependencies) when evaluating changes.

## Adding rules

- One rule per section or bullet.
- Keep each rule specific and actionable so the agent can check code against it.
- Optional: note which projects or file patterns the rule applies to.
