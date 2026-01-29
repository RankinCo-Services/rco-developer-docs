# AUTHORITATIVE – Beacon-App-Layout Contract

This is the **source of truth** for the contract between **@beacon/app-layout** and consuming apps (Beacon frontend and other RankinCo apps). It covers peer dependencies, navigation shape, layout component APIs, build/versioning, and RBAC UI (PageGuard, ActionGuard).

**Full doc:** [BEACON_APP_LAYOUT_CONTRACT.mdc](BEACON_APP_LAYOUT_CONTRACT.mdc) (Cursor-friendly).

**Derived from:** beacon-app-layout README.md, package.json, src/ (AppLayout, navigation.ts, NavigationContext, index.tsx), beacon-tenant-ui.d.ts. RBAC UI (PageGuard, ActionGuard) is part of the architecture contract; implementation may live in layout or tenant-ui.
