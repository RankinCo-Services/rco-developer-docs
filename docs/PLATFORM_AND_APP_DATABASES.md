# AUTHORITATIVE – Platform and App Databases (summary)

This document is a **concise summary**. The full authoritative doc is in **docs/PLATFORM_AND_APP_DATABASES.mdc**. The RCO copy script copies it to **docs/rco-standards/** and to **.cursor/references/**.

**Source of truth:** rco-developer-docs.

---

## Summary

- **Two databases:** **Platform DB** (`PLATFORM_DATABASE_URL`) holds Tenant, User, UserTenantAssociation, Role, Permission, TenantSettings, AuditEvent, App, TenantAppSubscription, State/Country. **App DB** (`DATABASE_URL`) holds app-domain tables (Project, Client, Invoice, etc.). App tables reference tenants by `tenant_id` (string) only; no FK to Platform DB.
- **Backend:** Instantiates `platformPrisma` and `appPrisma`; sets `app.set('platformPrisma', platformPrisma)`; passes **platformPrisma** into all beacon-tenant routers and middleware. beacon-tenant does not create its own DB client.
- **Use:** Identity, RBAC, audit, tenant settings → platformPrisma. App-domain data → appPrisma. Cross-DB: TenantSettings.tenant_client_id is a string; app resolves Client in App DB.

## Not yet implemented

- Physical DB split (migrations-platform / migrations-app and cutover were cancelled in the plan). If Platform and App still share one Postgres instance, document that; when splitting, use PLATFORM_DATABASE_URL and DATABASE_URL and run migrations per doc.

## Full doc

**docs/PLATFORM_AND_APP_DATABASES.mdc** (or **docs/rco-standards/** and **.cursor/references/** in a project after the copy script).
