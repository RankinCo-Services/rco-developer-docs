# Beacon architecture & services layer rules (secondary review)

This document defines **architecture, services layer, database, and auth** rules for Beacon and Beacon-based apps (3-app model: beacon-tenant, beacon-app-layout, app). The security-compliance subagent applies these rules **in addition to** the generic security rules when reviewing Beacon or Beacon-based codebases.

**References:** Architecture Refactor Plan, beacon-tenant/docs/SERVICES_LAYER_ARCHITECTURE.md, Beacon docs/ARCHITECTURE_ANALYSIS.md, PLATFORM_APP_DB_CUTOVER.md, AUTH_AND_AUTHORIZATION_FLOW.md.

---

## Architecture & package boundaries

- **beacon-tenant owns framework concerns only.** It owns multi-tenancy, auth, user management, invitations, RBAC, platform admin, and audit. Tenant-scoped backend routes for users, invitations, roles, permissions, tenant-settings, or tenants must live in `beacon-tenant/packages/tenant/src/routes/` (or platform-admin subfolder). Do not add them to `backend/src/routes/` in the app repo.
- **App backend only has app-specific routes.** Routes in `backend/src/routes/` must be app-domain only (e.g. projects, time entries, invoices, clients). Any route that serves tenant identity, RBAC, or tenant settings belongs in beacon-tenant.
- **Respect the 3-app dependency direction.** The app may depend on beacon-app-layout and beacon-tenant. beacon-tenant must not depend on the app or on beacon-app-layout. beacon-app-layout may depend only on beacon-tenant-ui (for layout-related pieces such as TenantSwitcher, UserProfile); it must not hold business logic or direct API calls beyond what is abstracted via tenant-ui. The app uses framework for auth, users, invitations, and layout.
- **Use the correct Prisma client per concern.** Identity, RBAC, UserTenantAssociation, TenantSettings, and audit must use `platformPrisma` (from `req.app.get('platformPrisma')`). App-domain data (e.g. projects, clients, invoices) must use `appPrisma`. Do not use platformPrisma for app-domain tables or appPrisma for Tenant/User/Role/Permission/UserTenantAssociation.

---

## Services layer (no direct tenant API calls)

- **No legacy fallback; one path only.** All tenant-scoped access must go through the service layer with tenant context set. Configured API + tenant context + service layer. Do not introduce or retain legacy URL patterns (e.g. `/api/tenant-settings/:tenant_id`) as primary or fallback.
- **No direct API calls to tenant-scoped endpoints.** Frontend and layout code must not call `/api/tenant-settings`, `/api/users`, `/api/invitations`, `/api/roles`, `/api/permissions`, `/api/tenants` (or platform-admin audit) via raw `fetch`, `api.get()`, or `getApi().get()` with a constructed URL. Use only the services exported from `@beacon/tenant-ui`: `tenantSettingsService`, `usersService`, `invitationService`, `rolesService`, `permissionsService`, `tenantService`, `BeaconApiClient`. The app does not construct URLs or call tenant-scoped endpoints directly.
- **No legacy URL patterns for tenant data.** Do not introduce or rely on paths that include `:tenant_id` in the URL for tenant-scoped data (e.g. `/api/tenant-settings/:tenant_id`). Backend must expose only context-based routes (tenant from `requireTenant`); callers must use the service layer with tenant context set.
- **Submodules use their own services.** Components in beacon-tenant-ui or beacon-app-layout that need tenant data (e.g. TenantSwitcher needing tenant settings) must use the appropriate service from `@beacon/tenant-ui` (e.g. `tenantSettingsService.getTenantSettings()`), not raw API calls or app-provided API calls.
- **Permission checks go through the service layer and must be fail-closed.** PageGuard and other permission checks must use `BeaconApiClient.checkPermission`, `permissionsService`, or cached permissions from tenant-ui—not direct `fetch` to `/api/permissions` or similar. Preserve fail-closed behavior: if the check fails or is unclear, deny access.
- **Tenant context must be set before calling tenant-scoped services.** Any code that calls tenant-ui services must run only when tenant context is set (e.g. tenantStore.currentTenantId). Do not call these services before TenantAuthGuard (or equivalent) has established the current tenant. All callers must ensure tenant context is set before calling service methods.
- **API client must send tenant context for tenant-scoped requests.** Requests to tenant-scoped endpoints must include the `x-tenant-id` header (from tenant store via the app’s API client/interceptor) when the user has a selected tenant. Backend `requireTenant` extracts tenant from `x-tenant-id` and sets `req.tenantId`. Platform-level endpoints (e.g. `/api/tenants`, `/api/platform-admin/*`) must not have tenant_id forced into them by the same interceptor.

**Correct vs wrong (from SERVICES_LAYER_ARCHITECTURE):**

- Correct: `import { tenantSettingsService } from '@beacon/tenant-ui'` then `tenantSettingsService.getTenantSettings()` / `tenantSettingsService.updateTenantSettings({ ... })`.
- Wrong: `api.get(\`/api/tenant-settings/${currentTenantId}\`)` or `api.put(...)` or raw `fetch` to tenant-scoped URLs. Wrong: constructing tenant-scoped URLs in app or submodule code.

---

## Database and migrations

- **App DB is tenant-scoped by tenant_id only.** Tables in the App DB must reference tenants via a `tenant_id` (string) column. Do not add foreign keys from the App DB to the Platform DB. Tenant identity is resolved in the app via `req.tenantId` from middleware.
- **Platform vs App data separation.** Tables that belong in the Platform DB (Tenant, User, UserTenantAssociation, Role, Permission, TenantSettings, AuditEvent, etc.) must not be added to the App DB schema. App-domain tables (e.g. Project, Client, Invoice) belong in the App DB schema only.
- **Migrations must be idempotent.** Every migration SQL file must be safe to re-run: use `CREATE TABLE IF NOT EXISTS`, `CREATE INDEX IF NOT EXISTS`, `CREATE UNIQUE INDEX IF NOT EXISTS`; wrap `ALTER TABLE ADD COLUMN` and `ALTER TABLE ADD CONSTRAINT` in `DO $$ ... IF NOT EXISTS (information_schema.columns / pg_constraint) ... END $$`; use `DROP TABLE IF EXISTS` / `DROP INDEX IF EXISTS` where applicable. Do not add non-idempotent `CREATE` or `ALTER` that assume a clean run.

---

## Auth and middleware order

- **Tenant-scoped API routes use verifyClerkJwt then requireTenant.** Any route that serves tenant-scoped data must run `verifyClerkJwt` first and then `requireTenant`. Do not add tenant-scoped handlers that skip either middleware.
- **Use req.tenantId from middleware, not from URL or body for authorization.** After `requireTenant`, use `req.tenantId` (set by middleware from UserTenantAssociation) for scoping queries and for authorization. Do not trust `tenant_id` from query or body for authorization decisions without going through requireTenant.
- **Platform-admin routes use requirePlatformAdmin.** Routes under `/api/platform-admin/*` must use `requirePlatformAdmin` (and typically verifyClerkJwt). Do not expose platform-admin behavior without this check.
- **Do not bypass or remove auth middleware to fix bugs.** If a route fails due to auth or tenant checks, fix the underlying issue (e.g. correct tenant_id, permissions, or middleware order). Do not remove or bypass verifyClerkJwt, requireTenant, or requirePermission to get a feature working.

---

## Summary table (for the subagent)

| Category | Rule in one line |
|----------|------------------|
| Architecture | Tenant-scoped routes live in beacon-tenant; app backend only has app-specific routes. |
| Architecture | Correct Prisma client: platformPrisma for identity/RBAC/audit, appPrisma for app data. |
| Architecture | Dependency direction: app → layout → tenant-ui; no reverse; layout only layout-related, no business logic. |
| Services layer | No legacy fallback; one path only—service layer + tenant context. No direct tenant API calls. |
| Services layer | No legacy :tenant_id routes; context-based routes only; use x-tenant-id header; fail-closed permission checks. |
| Services layer | Submodules and permission checks use service layer; tenant context set before calls. |
| Database | App DB uses tenant_id string only; no FK to Platform DB; Platform vs App table split. |
| Database | Migration SQL is idempotent (IF NOT EXISTS, DO $$ ... IF NOT EXISTS ... $$). |
| Auth/middleware | Tenant-scoped routes use verifyClerkJwt then requireTenant; use req.tenantId for scoping. |
| Auth/middleware | Platform-admin routes use requirePlatformAdmin; do not remove auth to fix bugs. |
