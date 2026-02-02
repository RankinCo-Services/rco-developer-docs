# RCO 3-App Architecture (Beacon and Beacon-based apps)

This document is the **source of truth** for the 3-app architecture used by Beacon and any RankinCo app built on the same model (beacon-tenant + beacon-app-layout + app). For the **enforcement checklist** used in security and architecture reviews, see **`.cursor/references/beacon-architecture-rules.md`** (in this repo and copied into projects).

---

## The three packages

| Package | Role |
|--------|------|
| **beacon-tenant** | Framework/infrastructure: multi-tenancy, auth, user management, invitations, RBAC, platform admin, audit. Backend (`@beacon/tenant`) + frontend (`@beacon/tenant-ui`). |
| **beacon-app-layout** | UI/layout: layout components, navigation, RBAC UI (PageGuard, ActionGuard). No business logic; no direct tenant API calls. |
| **App (e.g. Beacon frontend)** | Business logic and domain (e.g. PSA: projects, time, invoicing). Consumes framework; does not duplicate tenant/auth infrastructure. |

**Dependency direction:** App → beacon-app-layout → beacon-tenant. No reverse dependencies. beacon-app-layout depends only on beacon-tenant-ui for layout-related pieces (e.g. TenantSwitcher, UserProfile).

---

## Platform DB vs App DB (dual-database)

- **Platform DB** (`PLATFORM_DATABASE_URL`): Tenant, User, UserTenantAssociation, Role, Permission, TenantSettings, AuditEvent, etc. Owned by beacon-tenant; shared by all apps. Use **platformPrisma** (from `req.app.get('platformPrisma')`).
- **App DB** (`DATABASE_URL`): App-domain tables (e.g. Project, Client, Invoice). References tenants via `tenant_id` (string) only; no FK to Platform DB. Use **appPrisma**.

The host backend instantiates both Prisma clients and passes platformPrisma into beacon-tenant routers/middleware. beacon-tenant does not create its own DB client.

---

## Services layer (no direct tenant API calls)

- **Frontend and layout** must not call tenant-scoped endpoints (`/api/tenant-settings`, `/api/users`, `/api/invitations`, etc.) via raw `fetch` or `api.get()`. Use only **services exported from `@beacon/tenant-ui`** (e.g. `tenantSettingsService`, `usersService`, `BeaconApiClient`).
- **Tenant context** must be set (e.g. tenantStore.currentTenantId) before calling those services. Permission checks go through the service layer and must be fail-closed.
- **Backend** exposes context-based routes (tenant from `requireTenant`); no legacy `:tenant_id` in URL for tenant-scoped data.

---

## Where things live

- **Tenant-scoped backend routes** (users, invitations, roles, permissions, tenant-settings, tenants, platform-admin): **beacon-tenant** `packages/tenant/src/routes/`, not app `backend/src/routes/`.
- **App backend routes**: App-domain only (e.g. projects, time entries, invoices). App backend does not own tenant identity or RBAC routes.
- **Auth and middleware order**: Tenant-scoped routes use `verifyClerkJwt` then `requireTenant`. Use `req.tenantId` from middleware for scoping. Platform-admin routes use `requirePlatformAdmin`.

---

## Host-app routing and manifest (inversion)

When **beacon-tenant** is the host (e.g. inversion shell), the host **owns routing and nav**; hosted apps (PSA, GRC) supply a **manifest** (route definitions) and **page content** only. Apps do not own `<Routes>` or `NavigationProvider`; the host builds nav and routes from the manifest. See **[HOST_APP_ROUTING_AND_MANIFEST.md](HOST_APP_ROUTING_AND_MANIFEST.md)** (and [HOST_APP_ROUTING_AND_MANIFEST.mdc](HOST_APP_ROUTING_AND_MANIFEST.mdc)) for the full pattern, refactor sketch, and architecture-review checklist.

---

## References

- **Enforcement rules:** `.cursor/references/beacon-architecture-rules.md` (in this repo; copied into projects).
- **Host-app routing and manifest:** [HOST_APP_ROUTING_AND_MANIFEST.md](HOST_APP_ROUTING_AND_MANIFEST.md) — host owns routing/nav; app supplies manifest + content.
- **Beacon-specific deep dive:** Beacon repo `docs/ARCHITECTURE_ANALYSIS.md`.
- **Services layer detail:** beacon-tenant `docs/SERVICES_LAYER_ARCHITECTURE.md`.
