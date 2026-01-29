# RCO Developer Documents

RankinCo development standards, Cursor configs, and shared documentation. Use this repo as the single source of truth for team-wide standards and tooling—not tied to any one project.

## Contents

- **cursor/** – Cursor IDE configs (agents, rules, skills, references) for security review, code standards, and workflows.
- **scripts/** – Helper scripts to copy Cursor configs into a project.

## Using Cursor configs in a project

### Option 1: Copy manually

From this repo root, copy the `cursor/` contents into your project’s `.cursor/`:

```bash
# From your project root (e.g. Beacon, PSA)
mkdir -p .cursor
cp -r /path/to/rco-developer-docs/cursor/agents .cursor/
cp -r /path/to/rco-developer-docs/cursor/rules .cursor/
cp -r /path/to/rco-developer-docs/cursor/references .cursor/
# Optional: skills
cp -r /path/to/rco-developer-docs/cursor/skills .cursor/
```

Or use the copy script (run from your project root):

```bash
/path/to/rco-developer-docs/scripts/copy-cursor-config.sh
```

### Option 2: Clone and copy

Clone this repo alongside your projects, then run the script from your project:

```bash
cd /path/to/your-project
../rco-developer-docs/scripts/copy-cursor-config.sh
```

## Security review agent

The security-compliance subagent and related rule/skill help review code changes before commit and return a compliance report. See [cursor/agents/security-compliance.md](cursor/agents/security-compliance.md) and [cursor/references/security-rules.md](cursor/references/security-rules.md).

**Usage:** In Cursor, ask the agent: “Run a security compliance review on my current staged (or unstaged) changes and give me the report.” The agent will launch the security subagent and return the analysis.

## Adding or updating standards

1. Edit files in this repo (e.g. `cursor/references/security-rules.md`, `cursor/rules/*.mdc`).
2. Commit and push.
3. In each project that uses these configs, re-run the copy script or re-copy the updated `cursor/` contents.

## License

Internal use; adjust as needed for your organization.
