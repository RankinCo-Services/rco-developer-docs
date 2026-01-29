# AUTHORITATIVE – Audit System (summary)

This document is a **concise summary**. The full authoritative doc is in **docs/AUDIT_SYSTEM.mdc**. The RCO copy script copies it to **docs/rco-standards/** and to **.cursor/references/**.

**Source of truth:** rco-developer-docs.

---

## Summary

- **Scope:** Audit create, update, delete (not read). Event types: business, security, technical, metrics. Levels: info, security, error, audit_failure. Sensitive events synchronous (fail-safe); standard events async (guaranteed delivery).
- **Current state:** beacon-tenant provides AuditService (logBusinessEvent, logSecurityEvent, logTechnicalEvent, logMetricsEvent), logAuditEvent, AuditQueue, AuditWorker; audit middleware and helpers; Platform DB (AuditEvent, AuditQueue). Backend mounts audit routes and starts audit worker; app uses auditHelpers / logAuditEvent for CUD.
- **Owner:** beacon-tenant (audit service, worker, types); Beacon backend (platformPrisma, mount, start worker).

## Not yet implemented

- Full SOC2/retention (2 months), CSV export, encryption at rest, access control (tenant admin / platform admin).
- Dashboard (event velocity, by level/module, top users, recent security events); full-text search; health checks for audit system.
- Complete middleware auto-capture (before/after, IP/user agent) and route-level audit config.

## Full doc

**docs/AUDIT_SYSTEM.mdc** (requirements, current implementation, phases, not yet implemented).
