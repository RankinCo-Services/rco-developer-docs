# AUTHORITATIVE – Platform Readiness and Cache (summary)

This document is a **concise summary**. The full authoritative doc is in **docs/PLATFORM_READINESS_AND_CACHE.mdc**. The RCO copy script copies it to **docs/rco-standards/** and to **.cursor/references/**.

**Source of truth:** rco-developer-docs.

---

## Summary

- **Platform readiness:** beacon-tenant (tenant-ui) provides a readiness store and `usePlatformReady()` so components wait for auth, tenant, and (optionally) permissions before loading data. Flags: clerkReady, userReady, authTokenReady, tenantStoreReady, tenantSelected, tenantAuthorized, permissionsReady. Computed: canMakeAuthenticatedRequests, canLoadTenantData, isFullyReady.
- **Usage:** Data-loading components MUST use `usePlatformReady()` and wait for `canLoadTenantData` (and optionally `isFullyReady`) before loading tenant-scoped data. Do not load on `currentTenantId` alone.
- **Owner:** beacon-tenant (tenant-ui): platformReadyStore, TenantAuthGuard (sets flags), AuthSync, usePlatformReady.

## Not yet implemented

- Global cache (platform cache store with TTL, cache-first/stale-while-revalidate, usePermissions/usersService using cache).
- AuthSync coordination with TenantAuthGuard; retry logic for 401 when auth becomes ready.
- All data-loading pages (e.g. TimeTrackingTab, PortfolioTab) using usePlatformReady; PageGuard/ActionGuard using cached permissions.
- App stub template including readiness system; tests for readiness and cache.

## Full doc

**docs/PLATFORM_READINESS_AND_CACHE.mdc** (or **docs/rco-standards/** and **.cursor/references/** in a project after the copy script).
