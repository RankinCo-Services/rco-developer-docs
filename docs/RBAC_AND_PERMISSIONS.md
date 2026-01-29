# AUTHORITATIVE – RBAC and Permissions Model (summary)

This document is a **concise summary**. The full authoritative doc (description, data model, workflows, rules, not-yet-implemented) is in **docs/RBAC_AND_PERMISSIONS.mdc**. The RCO copy script copies it to project **docs/rco-standards/** and to **.cursor/references/** for easy viewing in Cursor.

**Source of truth:** rco-developer-docs; copied to projects at `docs/rco-standards/` when using the RCO copy script.

---

## Summary

- **RBAC:** Namespace-based permissions (e.g. `platform:platform-admin:tenants:view`, `psa:financial:invoices:view`). Users get permissions via **roles** (Role → RolePermission → Permission) and optionally **UserPermission**. All in Platform DB; backend uses **platformPrisma**.
- **Backend:** `requireTenant` then `requirePermission('namespace')`. Middleware uses platformPrisma, x-user-id, req.tenantId. Fail-closed.
- **Frontend:** Use only **@beacon/tenant-ui**: `permissionsService.getPermissions()`, `beaconApiClient.checkPermission(namespace, tenantId)`. No direct `/api/permissions` or `/api/permissions/check`. Fail-closed.
- **Catalog:** beacon-tenant `packages/tenant/src/permissions/catalog.ts` (PermissionDefinition, getPermissionsForApp). Seed via permissionSeeder / platformBootstrap.
- **Key files:** beacon-tenant (catalog, routes/permissions, routes/roles, middleware/requirePermission), tenant-ui (permissionsService, apiClient), Beacon backend (platform schema, permissionSeeder).

## Not yet implemented

- Subscription check in requirePermission (tenant must have TenantAppSubscription for app).
- Explicit deny in UserPermission.
- Hierarchical permission inheritance.

## Full doc

For full description, data model diagram, workflows, rules table, and references: **docs/RBAC_AND_PERMISSIONS.mdc** (or **docs/rco-standards/RBAC_AND_PERMISSIONS.mdc** and **.cursor/references/RBAC_AND_PERMISSIONS.mdc** in a project after running the copy script).
