# AUTHORITATIVE – Deploy and Deploy All Workflow

This is the **source of truth** for the mandatory deploy workflow used across RankinCo projects (Beacon, PSA, and future apps). When you copy the RCO Cursor config into a project, the agent follows this workflow when you say "deploy" or "deploy all".

**Full doc:** [DEPLOY_WORKFLOW.mdc](DEPLOY_WORKFLOW.mdc) (Cursor-friendly). **Derived from:** Beacon scripts (deploy-all.sh, pre-deploy-check.sh), Cursor rules (deploy-workflow, render-deployment-workflow, beacon.mdc).

## Exact workflow every time

1. **ESLint** — Zero errors (warnings OK). Run `npm run lint:fix` and `npm run lint:security:fix` in the relevant packages; verify with `npm run lint` and `npm run lint:security`. For deploy-all with submodules, run lint in each submodule that has changes.
2. **Security compliance** — Run per `.cursor/agents/security-compliance.md` and `.cursor/skills/security-review-before-commit/SKILL.md`. Produce and show the compliance report. If FAIL, fix or document exceptions; rerun until PASS.
3. **Architecture review** — For Beacon/Beacon-based apps: `.cursor/references/beacon-architecture-rules.md`. For other projects: project-specific architecture rules. Make any recommended changes for compliance.
4. **Commit and push** — Run the project's deploy script (e.g. `./deploy "message"` or `./scripts/deploy-all.sh "message"` for cross-repo). The script runs pre-deploy checks unless `--skip-checks`.
5. **Monitor Render** — Use Render MCP: `list_workspaces`, `select_workspace` (RankinCo Services, `tea-d5qerqf5r7bs738jbqmg`), then `list_deploys`, `list_logs` (build and service), `get_deploy`. Review logs and fix any errors that prevent services from going live. **Repeat (fix → commit/push or redeploy → monitor) until services are live.**

## Goal

Unless the user says otherwise, the goal is to run the **entire pipeline** deployment to Render and **fix issues until the services are live**. Do not consider the workflow complete until the relevant Render services are live.

## Security and architecture

Security and architecture reviews are **mandatory** for all commits, pushes, deploys, and for any Cursor plans and solution planning. All committed code must comply.

## References

- **Cursor rules:** `.cursor/rules/deploy-workflow.mdc`, `.cursor/rules/render-deployment-workflow.mdc` (after copying config into a project).
- **Render:** We always deploy to **RankinCo Services** workspace. See [RENDER_DEPLOYMENT_RUNBOOK.md](RENDER_DEPLOYMENT_RUNBOOK.md).
- **Cross-repo / submodules:** See [CROSS_REPO_DEVELOPMENT.md](CROSS_REPO_DEVELOPMENT.md) and [SUBMODULE_DEPLOY_RUNBOOK.md](SUBMODULE_DEPLOY_RUNBOOK.md).
