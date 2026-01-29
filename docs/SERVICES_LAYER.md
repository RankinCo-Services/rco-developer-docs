# AUTHORITATIVE – Services Layer (summary)

This document is a **concise summary**. The full authoritative doc is in **docs/SERVICES_LAYER.mdc**. The RCO copy script copies it to **docs/rco-standards/** and to **.cursor/references/**.

**Source of truth:** rco-developer-docs.

---

## Summary

- **Rule:** All tenant-scoped data (tenant settings, users, invitations, permissions, roles, tenants list for current user) is accessed **only** via services exported from **@beacon/tenant-ui**. No direct `fetch`, `api.get()`, or `getApi().get()` to tenant-scoped URLs. No legacy `:tenant_id` in URL.
- **Services:** `tenantSettingsService`, `usersService`, `invitationService`, `rolesService`, `permissionsService`, `tenantService`, `BeaconApiClient`. Tenant context (e.g. `tenantStore.currentTenantId`) must be set before calling; API client sends `x-tenant-id` for tenant-scoped requests.
- **Backend:** Context-based routes only (tenant from `requireTenant`); no tenant-scoped routes with `:tenant_id` in path.
- **Current state:** App (SettingsTab, CompanyInformationTab) and TenantSwitcher use `tenantSettingsService`. Platform-level endpoints (e.g. `/api/platform-admin/tenants`) may be called directly when implementing platform-admin UI; they are not tenant-scoped.

## Not yet implemented

- Remove any remaining legacy `/:tenant_id` routes from beacon-tenant if still present.
- Ensure all layout and app code paths use only the service layer for tenant-scoped data.

## Full doc

**docs/SERVICES_LAYER.mdc** (or **docs/rco-standards/** and **.cursor/references/** in a project after the copy script).
