# Render Deployment Runbook (RCO source of truth)

RankinCo apps deploy to **Render**. This runbook is the source of truth for monitoring and troubleshooting deployments. It applies to Beacon, PSA, and any other RCO app on Render.

## We always deploy to RankinCo Services workspace

All RCO app services live in the **RankinCo Services** workspace on Render.

- **Workspace:** RankinCo Services  
- **Owner ID:** `tea-d5qerqf5r7bs738jbqmg`

To list or monitor services: use Render MCP `list_workspaces`, then `select_workspace` with the RankinCo Services workspace ID above, then `list_services` to list any service. You can always use RankinCo Services workspace to list any RCO app service.

## Process for reviewing deployment errors

1. **Find service ID** — Render MCP: `list_workspaces`, then `select_workspace` (owner ID `tea-d5qerqf5r7bs738jbqmg`), then `list_services`. Or use the Render API with `RENDER_API_KEY` (see project-specific docs).
2. **Check deployment status** — MCP `list_deploys` with the service ID.
3. **Review build logs** — MCP `list_logs` with type `build`.
4. **Review service logs** — MCP `list_logs` with type `service`.
5. **Get deploy details** — MCP `get_deploy` with service ID and deploy ID.
6. **Trigger redeploy** — Render API `POST /v1/services/{serviceId}/deploys` (no MCP tool).

## Common issues

- **Submodule commit not pushed** — Push the submodule first: `cd <submodule> && git push origin main`.
- **TypeScript build errors** — Fix locally, commit, then redeploy.
- **Missing dependencies** — Ensure `npm install` runs before build in the Render build command.

## Project-specific runbooks

Individual projects (e.g. Beacon) may have additional runbooks for initial Render setup (create Postgres, web service, static site) and env vars. See the project's `docs/` and `DEPLOYMENT.md`. The **workflow** (ESLint → security → architecture → deploy script → monitor Render) and **workspace** (RankinCo Services) are the same for all RCO apps.
