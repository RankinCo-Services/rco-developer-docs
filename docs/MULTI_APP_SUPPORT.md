# AUTHORITATIVE – Multi-App Support

This is the **source of truth** for multi-app support on the Beacon platform: one platform hosting multiple apps (e.g. PSA, Reg E, Card Fraud) with tenant subscriptions.

**Full doc:** [MULTI_APP_SUPPORT.mdc](MULTI_APP_SUPPORT.mdc) (Cursor-friendly).

**Derived from:** Beacon docs/MULTI_APP_SUPPORT_ANALYSIS.md, Beacon backend prisma/platform/schema.prisma (App, TenantAppSubscription), beacon-tenant requirePermission (app_id). Current state: schema and permission namespacing exist; app switcher, subscription APIs, and subscription-gated routes are not yet implemented.
