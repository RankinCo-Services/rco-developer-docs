# Cross-Repo Development (main app + submodules)

This document describes the **pattern** for RCO apps that are built from a main repo and one or more git submodules (e.g. Beacon = Beacon + beacon-tenant + beacon-app-layout). Use it as the source-of-truth pattern; each project adapts names and paths.

## Mindset

When you build a feature that touches more than one repo, treat the feature as **one unit**: same deploy, linked git history, and consistent commit messages across repos.

## Mandatory pre-deploy checks (Cursor)

Before running the project's deploy or deploy-all script, the agent must run: (1) **ESLint** until zero errors (warnings OK), (2) **security compliance** (`.cursor/agents/security-compliance.md` and `.cursor/skills/security-review-before-commit/SKILL.md`), (3) **architecture review** (project-specific, e.g. `.cursor/references/beacon-architecture-rules.md` for Beacon). All code must comply; then run the deploy script. After push, monitor Render via MCP and fix errors until services are live.

## Workflow: one feature, multiple repos

1. **Code** — Edit main repo and/or submodules as needed.
2. **Deploy** — Use the project's **deploy-all** script (e.g. `./scripts/deploy-all.sh "Feature: your message"`) so all repos are committed, pushed, and deployed together.

### Order of operations (typical deploy-all)

1. **Submodules first** — For each submodule that has changes: run lint (if present), update CHANGELOG if the script does it, commit and push.
2. **Main repo** — Run pre-deploy checks. If there are changes, update CHANGELOG, then `git add -A` (including submodule refs), commit, push.

## Commit messages

- **Main repo:** Use the message as given (e.g. `Feature: Auth 401 fix`).
- **Submodules:** Often prefixed with the app name (e.g. `Beacon: Feature: Auth 401 fix`) so history is clear.

## If submodule push fails (e.g. behind origin/main)

```bash
cd <submodule>
git pull --rebase origin main
# fix any conflicts, then:
git push origin main
```

Then re-run deploy-all or finish the main repo with `git add <submodule> && ./deploy "..."`.

## See also

- [DEPLOY_WORKFLOW.md](DEPLOY_WORKFLOW.md) — Full mandatory workflow.
- [SUBMODULE_DEPLOY_RUNBOOK.md](SUBMODULE_DEPLOY_RUNBOOK.md) — Manual steps when only a submodule has changes.
