# RCO Developer Documents

RankinCo development standards, Cursor configs, and shared documentation. Use this repo as the single source of truth for team-wide standards and tooling—not tied to any one project.

## Contents

- **cursor/** – Cursor IDE configs (agents, rules, skills, references) for security review, ESLint enforcement, **deploy workflow**, **Render deployment**, and code standards.
- **docs/** – Standards documentation (both .md and .mdc): [ESLint standard](docs/ESLINT_STANDARD.md), [Deploy workflow](docs/DEPLOY_WORKFLOW.md), [Render deployment runbook](docs/RENDER_DEPLOYMENT_RUNBOOK.md), [Cross-repo development](docs/CROSS_REPO_DEVELOPMENT.md), [Submodule deploy runbook](docs/SUBMODULE_DEPLOY_RUNBOOK.md), [3-app architecture](docs/ARCHITECTURE_3APP_MODEL.md), [Architecture analysis (full)](docs/ARCHITECTURE_ANALYSIS.md), [RBAC and permissions](docs/RBAC_AND_PERMISSIONS.md) (concise .md + full .mdc). All files in docs/ live here; the copy script copies them to the project.
- **scripts/** – [copy-cursor-config.sh](scripts/copy-cursor-config.sh) copies `cursor/` into the project’s `.cursor/`, copies `docs/` into the project’s `docs/rco-standards/`, and copies `docs/*.mdc` into the project’s `.cursor/references/` for easy developer viewing in Cursor.

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

Or use the copy script (run from your project root). The script merges **cursor/** into `.cursor/` (agents, rules, references, skills), copies **docs/** into **docs/rco-standards/** (all .md and .mdc), and copies **docs/*.mdc** into **.cursor/references/** so full authoritative .mdc docs appear in Cursor references for easy viewing.

```bash
/path/to/rco-developer-docs/scripts/copy-cursor-config.sh
# Optional: pass a target directory
/path/to/rco-developer-docs/scripts/copy-cursor-config.sh /path/to/your-project
```

### Option 2: Clone and copy

Clone this repo alongside your projects, then run the script from your project:

```bash
cd /path/to/your-project
../rco-developer-docs/scripts/copy-cursor-config.sh
```

After copying, the project has RCO rules in `.cursor/`, foundation docs in `docs/rco-standards/` (both .md and .mdc), and full .mdc topic docs in `.cursor/references/` for easy viewing in Cursor.

## Deploy workflow (all RCO projects)

When you say **"deploy"** or **"deploy all"**, the agent runs the **mandatory deploy workflow** defined in [cursor/rules/deploy-workflow.mdc](cursor/rules/deploy-workflow.mdc) and [cursor/rules/render-deployment-workflow.mdc](cursor/rules/render-deployment-workflow.mdc):

1. **ESLint** (zero errors; warnings OK)
2. **Security compliance** (agent + skill)
3. **Architecture review** (Beacon-based: beacon-architecture-rules; others: project-specific)
4. **Commit and push** via the project’s deploy script (e.g. `./deploy` or `./scripts/deploy-all.sh`)
5. **Monitor Render** via Render MCP until services are live

**Goal:** Run the entire pipeline to Render and fix issues until services are live. We always deploy to the **RankinCo Services** workspace (`tea-d5qerqf5r7bs738jbqmg`). Use `list_workspaces`, then `select_workspace` (RankinCo Services), then `list_services` to list any RCO app service.

**Docs (source of truth):** [docs/DEPLOY_WORKFLOW.md](docs/DEPLOY_WORKFLOW.md), [docs/RENDER_DEPLOYMENT_RUNBOOK.md](docs/RENDER_DEPLOYMENT_RUNBOOK.md), [docs/CROSS_REPO_DEVELOPMENT.md](docs/CROSS_REPO_DEVELOPMENT.md), [docs/SUBMODULE_DEPLOY_RUNBOOK.md](docs/SUBMODULE_DEPLOY_RUNBOOK.md), [docs/ARCHITECTURE_3APP_MODEL.md](docs/ARCHITECTURE_3APP_MODEL.md), [docs/ARCHITECTURE_ANALYSIS.md](docs/ARCHITECTURE_ANALYSIS.md). After running the copy script, these live in the project at `docs/rco-standards/`.

## Architecture (Beacon and Beacon-based apps)

**3-app model:** beacon-tenant (framework) + beacon-app-layout (UI/layout) + app (business logic). See [docs/ARCHITECTURE_3APP_MODEL.md](docs/ARCHITECTURE_3APP_MODEL.md) for a short summary and [docs/ARCHITECTURE_ANALYSIS.md](docs/ARCHITECTURE_ANALYSIS.md) for the full architecture analysis (source of truth in this repo; copied to projects at `docs/rco-standards/`).

**Enforcement:** The **architecture rules** (checklist used in security and deploy reviews) are in [cursor/references/beacon-architecture-rules.md](cursor/references/beacon-architecture-rules.md). They are mandatory for all commits and deploys on Beacon and Beacon-based apps. After copying config into a project, the agent uses this file for architecture review.

## Security review agent

The security-compliance subagent and related rule/skill review code changes before commit and return a compliance report. See [cursor/agents/security-compliance.md](cursor/agents/security-compliance.md) and [cursor/references/security-rules.md](cursor/references/security-rules.md).

**Beacon / Beacon-based apps:** When reviewing Beacon or Beacon-based codebases (3-app model), the subagent also applies [cursor/references/beacon-architecture-rules.md](cursor/references/beacon-architecture-rules.md) (architecture boundaries, services layer, database/migrations, auth middleware). This secondary document aligns with the Architecture Refactor Plan and beacon-tenant/docs/SERVICES_LAYER_ARCHITECTURE.md.

**Automatic on every code change:** The rule `cursor/rules/security-review.mdc` is set to `alwaysApply: true`. In any project that has copied this config, the agent is instructed to run the security-compliance subagent for **every** change set before recommending or proceeding with commit. No manual trigger is required—the subagent is part of the commit workflow.

**Manual usage:** You can also ask: “Run a security compliance review on my current staged (or unstaged) changes and give me the report.” The agent will launch the security subagent and return the analysis.

## ESLint (all projects)

**ESLint runs for every code change** in every project that uses this config. The rule `cursor/rules/eslint-after-changes.mdc` is set to `alwaysApply: true`. After any code change, the agent must run `lint:fix` and (if present) `lint:security:fix`, then verify with `lint` and `lint:security` in the appropriate directory before considering code complete or recommending commit.

**Required setup:** Each project (and each package in a monorepo or submodule) must have `lint`, `lint:fix`, and optionally `lint:security` / `lint:security:fix` scripts in package.json. See **[docs/ESLINT_STANDARD.md](docs/ESLINT_STANDARD.md)** for the full standard, setup checklist, and enforcement details.

## Adding or updating standards

1. Edit files in this repo (e.g. `cursor/references/security-rules.md`, `cursor/rules/*.mdc`, `docs/*.md`).
2. Commit and push.
3. In each project that uses these configs, re-run the copy script: `../rco-developer-docs/scripts/copy-cursor-config.sh`. This merges updated `cursor/` and copies updated `docs/` to `docs/rco-standards/`.

## License

Internal use; adjust as needed for your organization.
