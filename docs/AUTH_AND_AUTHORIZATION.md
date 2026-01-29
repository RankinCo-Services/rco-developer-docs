# AUTHORITATIVE – Auth and Authorization (summary)

This document is a **concise summary**. The full authoritative doc is in **docs/AUTH_AND_AUTHORIZATION.mdc**. The RCO copy script copies it to **docs/rco-standards/** and to **.cursor/references/**.

**Source of truth:** rco-developer-docs.

---

## Summary

- **Authentication** = Who is this user? (Clerk + JWT). **Tenant authorization** = Is this user allowed to use this tenant? (UserTenantAssociation). **Permission/RBAC** = Does this user have permission to do X? (roles, permissions, platform admin).
- **Ownership:** Beacon app wires Clerk, API client, ProtectedRoute; beacon-tenant (tenant-ui) owns auth sync, tenant selection/guard, readiness, tenant/permissions services; beacon-tenant (tenant backend) owns JWT verification, requireTenant, requirePermission, requirePlatformAdmin; Beacon backend mounts routes and provides platformPrisma/appPrisma.
- **Flow:** configureBeacon → TenantAuthProvider → Clerk → AuthSync (token + readiness) → ProtectedRoute → TenantAuthGuard (tenant + permissions bootstrap) → API interceptor adds tenant_id for tenant-scoped requests → backend verifyClerkJwt → requireTenant → requirePermission (optional).

## Full doc

**docs/AUTH_AND_AUTHORIZATION.mdc** (step-by-step ownership, request flow, summary table).
