# Beacon 3-App Architecture Analysis

**Source of truth:** This document lives in **rco-developer-docs** and is copied into projects at `docs/rco-standards/ARCHITECTURE_ANALYSIS.md`. Edit here and re-run the copy script in each project to update.

---

## Platform DB vs App DB (Dual-Database Architecture)

The backend uses **two PostgreSQL databases** and two Prisma clients:

| **Platform DB** (`PLATFORM_DATABASE_URL`) | **App DB (PSA)** (`DATABASE_URL`) |
|-------------------------------------------|----------------------------------|
| State, Country | Person, Team, TeamMember, Department |
| Tenant, App, TenantAppSubscription | Client, Contact, Lead, Opportunity, Proposal, Sale, Stage |
| User, UserTenantAssociation, UserRole | ClientNote, team join tables |
| Role, Permission, RolePermission, UserPermission | Project, ProjectTeam, WorkItem*, TimeEntry, Timesheet |
| TenantSettings | Invoice, Account, JournalEntry, JournalLine, Payment |
| AuditEvent, AuditQueue, ErrorLog | Note, NoteAttachment, CustomFieldDefinition, CustomFieldValue |

- **Platform DB**: Identity, RBAC, app registry, TenantSettings, audit, reference (State/Country). Owned by platform/beacon-tenant; shared by all apps.
- **App DB (PSA)**: Person, Client, Project, WorkItem, TimeEntry, Invoice, etc. References tenants by `tenant_id` (string); no FK to Platform DB.
- **Cross-DB**: `TenantSettings.tenant_client_id` remains a string; the app resolves Client in App DB. All app tables keep `tenant_id` (string).

The Beacon API instantiates `platformPrisma` (from `PLATFORM_DATABASE_URL`) and `appPrisma` (from `DATABASE_URL`), sets `app.set('platformPrisma', platformPrisma)` and `app.set('appPrisma', appPrisma)`, and passes **platformPrisma** into all beacon-tenant routers and middleware. **beacon-tenant** receives the platform Prisma client from the host; it does not create its own. Middleware (`requireTenant`, `requirePermission`) reads `req.app.get('platformPrisma')` when set by the host.

---

## Current Architecture Overview

### The Three Packages

1. **`beacon-tenant`** (Framework/Infrastructure)
   - **Backend (`@beacon/tenant`)**: Middleware, routes, permissions, audit
   - **Frontend (`@beacon/tenant-ui`)**: Auth, tenant selection, user management UI, state

2. **`beacon-app-layout`** (UI/Layout Framework)
   - Layout components (AppLayout, Sidebar, Breadcrumbs, etc.)
   - Navigation system
   - RBAC UI components (PageGuard, ActionGuard)

3. **`beacon` (frontend)** (Business Logic/PSA App)
   - PSA-specific pages and components
   - Business domain logic (projects, time tracking, invoicing, etc.)
   - App-specific services

---

## ✅ What Works Well

### 1. **Clear Separation of Concerns (Mostly)**
- **beacon-tenant** correctly owns:
  - Multi-tenancy infrastructure
  - Authentication/authorization
  - Tenant lifecycle (creation, selection, switching)
  - User management (roles, permissions, invitations)
  - Platform admin capabilities

- **beacon-app-layout** correctly owns:
  - Reusable layout components
  - Navigation structure
  - Consistent UI patterns

- **beacon (frontend)** correctly owns:
  - PSA business logic
  - Domain-specific pages

### 2. **Reusability**
- `beacon-tenant` can be used by multiple apps
- `beacon-app-layout` provides consistent UI across apps
- Apps focus on business logic

### 3. **Type Safety**
- TypeScript across all packages
- Shared types via exports

---

## ⚠️ Issues & Concerns

### 1. **Incomplete Separation**

#### Problem: User Management Split
- **Current**: `UsersTab.tsx` and `usersService.ts` are in `beacon` (frontend)
- **Should be**: In `beacon-tenant` since it's tenant-scoped infrastructure
- **Impact**: Can't reuse user management across apps

#### Problem: Auth Pages Split
- **Current**: `SignInPage.tsx`, `SignUpPage.tsx`, `UserProfilePage.tsx` in `beacon` (frontend)
- **Should be**: In `beacon-tenant` as generic, customizable pages
- **Impact**: Each app must duplicate auth pages

### 2. **Dependency Direction Issues**

#### Current Flow:
```
beacon (app) 
  → depends on → beacon-app-layout
  → depends on → beacon-tenant
```

#### Problem: Circular/Unclear Dependencies
- `beacon-app-layout` depends on `beacon-tenant-ui` (for TenantSwitcher, UserProfile)
- `beacon` depends on both
- But `beacon-tenant` shouldn't depend on `beacon-app-layout`
- **This is actually correct**, but the boundaries need clarification

### 3. **Backend/Frontend Split in `beacon-tenant`**

#### Current Structure:
```
beacon-tenant/
  packages/
    tenant/        # Backend (Express middleware, routes)
    tenant-ui/     # Frontend (React components, services)
```

#### Issue: Mixed Concerns
- Backend and frontend in same repo but different packages
- Backend routes are in `beacon-tenant/packages/tenant/src/routes/`
- But some routes are in `backend/src/routes/` (users.ts, invitations.ts)
- **Inconsistency**: Should all tenant-scoped routes be in `beacon-tenant`?

### 4. **Platform Readiness & Caching System** ✅ (NEW)

#### Solution: Foundational Services Guarantee
- **Platform Readiness Store**: Tracks initialization of all foundational services (Clerk, auth token, tenant authorization)
- **Mandatory Readiness Checks**: All components MUST wait for readiness before loading data
- **API Interceptor Enforcement**: Requests are queued if platform not ready, automatically processed when ready
- **Prevents Race Conditions**: Eliminates 401 errors from requests made before auth token is set

#### Solution: Global Cache System
- **Hybrid Cache**: In-memory + localStorage for fast access and persistence
- **Extensible Design**: Apps can cache app-specific data (projects, work items, etc.)
- **Webhook-Based Invalidation**: Real-time cache invalidation for multi-user scenarios
- **Cache-First Pattern**: All data fetching goes through cache service (mandatory)
- **Stale-While-Revalidate**: Returns cached data immediately, refreshes in background
- **Enterprise-Ready**: Abstract cache interface supports future Redis migration

#### Implementation
- **beacon-tenant**: Core readiness store, cache store, cache service, webhook handler
- **beacon-app-layout**: PageGuard/ActionGuard use cached permissions
- **beacon (app)**: All services use caching, all pages wait for readiness
- **Mandatory Patterns**: No legacy code - everything follows new architecture

### 5. **Missing Abstraction Layers**

#### Problem: Direct API Calls
- `beacon-app-layout`'s `PageGuard` uses `fetch()` directly
- Should use a service abstraction from `beacon-tenant`
- Apps must configure API URLs manually

#### Problem: No Configuration Layer
- Apps must manually configure:
  - API base URL
  - Clerk keys
  - Navigation structure
- Should have a unified config system

### 5. **State Management Fragmentation**

#### Current:
- `beacon-tenant-ui`: Zustand store for tenant state
- `beacon`: Likely has its own state management
- No shared state management pattern

#### Issue: State Sync
- Tenant state in `beacon-tenant`
- App state in `beacon`
- How do they sync? (Currently via Zustand store, which works but isn't explicit)

---

## 🎯 Recommended Architecture

### Core Principle: **Layered Architecture with Clear Boundaries**

```
┌─────────────────────────────────────────────────────────┐
│                    beacon (App)                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │         Business Logic & Domain Pages           │  │
│  │  (Projects, Time Tracking, Invoicing, etc.)     │  │
│  └──────────────────────────────────────────────────┘  │
│                        ↓ depends on                     │
┌─────────────────────────────────────────────────────────┐
│              beacon-app-layout                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │     Layout, Navigation, UI Components             │  │
│  │  (AppLayout, Sidebar, Breadcrumbs, etc.)         │  │
│  └──────────────────────────────────────────────────┘  │
│                        ↓ depends on                     │
┌─────────────────────────────────────────────────────────┐
│              beacon-tenant (Framework)                 │
│  ┌──────────────────────┬──────────────────────────┐  │
│  │   @beacon/tenant     │   @beacon/tenant-ui      │  │
│  │   (Backend)          │   (Frontend)             │  │
│  │                      │                          │  │
│  │ • Middleware         │ • Auth Components        │  │
│  │ • Routes             │ • Tenant Selection       │  │
│  │ • Permissions        │ • User Management        │  │
│  │ • Audit              │ • Invitations            │  │
│  │ • Platform Admin     │ • State Management       │  │
│  └──────────────────────┴──────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## 📋 Detailed Recommendations

### 1. **Complete the Migration to `beacon-tenant`**

#### Move to `beacon-tenant/packages/tenant-ui`:
- ✅ `SignInPage.tsx` → Generic, customizable
- ✅ `SignUpPage.tsx` → Generic, customizable  
- ✅ `UserProfilePage.tsx` → Clerk account management
- ✅ `UsersTab.tsx` → `UsersManagementPage.tsx` (generic user management)
- ✅ `usersService.ts` → User management service

#### Make Them Customizable:
```typescript
// beacon-tenant/packages/tenant-ui/src/pages/SignInPage.tsx
export interface SignInPageProps {
  branding?: {
    logo?: string
    title?: string
    subtitle?: string
  }
  afterSignInUrl?: string
  signUpUrl?: string
}

export default function SignInPage({ branding, ...props }: SignInPageProps) {
  // Generic implementation with customization points
}
```

### 2. **Consolidate Backend Routes**

#### Current Problem:
- Some routes in `beacon-tenant/packages/tenant/src/routes/`
- Some routes in `backend/src/routes/` (users.ts, invitations.ts)

#### Recommendation:
**All tenant-scoped routes should be in `beacon-tenant`:**

```
beacon-tenant/packages/tenant/src/routes/
  ├── tenants.ts           ✅ (already there)
  ├── roles.ts             ✅ (already there)
  ├── permissions.ts       ✅ (already there)
  ├── users.ts             ⚠️  (move from backend/src/routes/)
  ├── invitations.ts       ⚠️  (move from backend/src/routes/)
  └── platform-admin/
      └── tenants.ts       ✅ (already there)
```

**Backend (`backend/src/routes/`) should only have:**
- App-specific routes (projects, time entries, invoices, etc.)
- Routes that are NOT tenant-scoped

### 3. **Create a Configuration System**

#### Problem: Apps manually configure everything

#### Solution: Unified Config API

```typescript
// beacon-tenant/packages/tenant-ui/src/config.ts (enhanced)
export interface BeaconConfig {
  // Auth
  clerk: {
    publishableKey: string
  }
  
  // API
  api: {
    baseUrl: string
  }
  
  // App-specific
  app: {
    name: string
    logo?: string
    branding?: {
      primaryColor?: string
      // ... other branding
    }
  }
  
  // Navigation (optional - app can override)
  navigation?: NavigationConfig
}

export function configureBeacon(config: BeaconConfig) {
  // Set up all infrastructure
  // Configure API client
  // Set up auth
  // Initialize stores
}
```

### 4. **Service Abstraction Layer**

#### Problem: Direct API calls scattered

#### Solution: Service layer in `beacon-tenant`

```typescript
// beacon-tenant/packages/tenant-ui/src/services/apiClient.ts
export class BeaconApiClient {
  constructor(baseUrl: string, authToken: string) {
    // Configured axios instance
  }
  
  // Permission checks
  async checkPermission(namespace: string): Promise<boolean>
  
  // User management
  async getUsers(tenantId: string): Promise<User[]>
  async updateUserRole(...): Promise<void>
  
  // Invitations
  async createInvitation(...): Promise<Invitation>
  // etc.
}
```

Then `PageGuard` uses this instead of raw `fetch()`.

### 5. **Clear Package Boundaries**

#### `beacon-tenant` Should Provide:
- ✅ Multi-tenancy infrastructure (backend + frontend)
- ✅ Authentication/authorization
- ✅ User management (UI + services)
- ✅ Invitation workflows
- ✅ Platform admin capabilities
- ✅ Permission system
- ✅ Audit logging
- ✅ State management (tenant store)

#### `beacon-app-layout` Should Provide:
- ✅ Layout components
- ✅ Navigation system
- ✅ UI primitives (breadcrumbs, tabs, etc.)
- ✅ RBAC UI components (PageGuard, ActionGuard)
- ❌ Should NOT have business logic
- ❌ Should NOT directly call APIs (use services from beacon-tenant)

#### `beacon` (App) Should Provide:
- ✅ Business domain logic
- ✅ App-specific pages
- ✅ App-specific services
- ✅ App-specific components
- ❌ Should NOT duplicate tenant/auth infrastructure
- ❌ Should NOT have user management (use from beacon-tenant)

### 6. **Backend Architecture**

#### Current Structure:
```
backend/
  src/
    routes/
      users.ts          ⚠️  Should be in beacon-tenant
      invitations.ts    ⚠️  Should be in beacon-tenant
      projects.ts       ✅  App-specific
      invoices.ts       ✅  App-specific
```

#### Recommended Structure:
```
backend/
  src/
    routes/
      projects.ts       ✅  App-specific
      invoices.ts       ✅  App-specific
      timeEntries.ts    ✅  App-specific
      # ... all app-specific routes

# beacon-tenant routes are imported and mounted:
import { 
  tenantsRouter, 
  usersRouter,        # NEW: moved from backend
  invitationsRouter,  # NEW: moved from backend
  rolesRouter,
  permissionsRouter 
} from '@beacon/tenant'

app.use('/api/tenants', tenantsRouter)
app.use('/api/users', usersRouter)
app.use('/api/invitations', invitationsRouter)
// etc.
```

---

## 🏗️ Enterprise-Grade Improvements

### 1. **Plugin/Extension System**

For enterprise customers who need customization:

```typescript
// beacon-tenant/packages/tenant-ui/src/types/plugins.ts
export interface BeaconPlugin {
  name: string
  hooks?: {
    beforeSignIn?: (user: User) => Promise<void>
    afterTenantSwitch?: (tenant: Tenant) => Promise<void>
    // ... extensibility points
  }
  components?: {
    userProfileMenu?: React.ComponentType
    tenantSwitcher?: React.ComponentType
  }
}

export function registerPlugin(plugin: BeaconPlugin) {
  // Register hooks and overrides
}
```

### 2. **Multi-App Support**

Current: `beacon-tenant` assumes single app namespace

**Enhancement**: Support multiple apps per tenant

```typescript
// Tenant can subscribe to multiple apps
interface Tenant {
  id: string
  name: string
  subscriptions: AppSubscription[]  // PSA, InfoSec-GRC, etc.
}

// Navigation adapts to subscribed apps
// Permissions are app-scoped
```

### 3. **Theming System**

For enterprise white-labeling:

```typescript
// beacon-tenant/packages/tenant-ui/src/theming.ts
export interface Theme {
  colors: {
    primary: string
    secondary: string
    // ...
  }
  fonts: {
    heading: string
    body: string
  }
  logo?: string
}

export function applyTheme(theme: Theme) {
  // Apply to all beacon-tenant and beacon-app-layout components
}
```

### 4. **Observability & Monitoring**

Add to `beacon-tenant`:

```typescript
// beacon-tenant/packages/tenant/src/monitoring.ts
export interface MonitoringConfig {
  onError?: (error: Error, context: any) => void
  onPermissionDenied?: (user: string, permission: string) => void
  onTenantSwitch?: (tenant: Tenant) => void
}

export function configureMonitoring(config: MonitoringConfig) {
  // Hook into all tenant operations
}
```

### 5. **Documentation & Type Safety**

- ✅ Comprehensive TypeScript types
- ✅ API documentation (OpenAPI/Swagger)
- ✅ Component documentation (Storybook?)
- ✅ Architecture decision records (ADRs)

---

## 🎯 Recommended Migration Path

### Phase 1: Complete Infrastructure Migration ✅ **COMPLETED**
1. ✅ Move `usersService.ts` → `beacon-tenant`
2. ✅ Move `UsersTab.tsx` → `beacon-tenant` (as `UsersManagementPage.tsx`)
3. ✅ Move `SignInPage.tsx`, `SignUpPage.tsx`, `UserProfilePage.tsx` → `beacon-tenant`
4. ✅ Move backend route `users.ts` → `beacon-tenant/packages/tenant/src/routes/` (invitations remains in backend due to Person model dependency)
5. ✅ Update all imports in `beacon` (frontend)

### Phase 2: Service Abstraction ✅ **COMPLETED**
1. ✅ Create `BeaconApiClient` in `beacon-tenant` with `checkPermission`, `users`, `invitations`
2. ✅ Update `PageGuard` to use service layer (fail-closed preserved)
3. ✅ Create unified config system (`configureBeacon`, `BeaconConfig`)
4. ✅ Document configuration API (`docs/CONFIG.md`)

### Phase 3: Enterprise Features ✅ **COMPLETED** (Plugin system excluded per plan)
1. ~~Plugin system~~ (Excluded per plan)
2. ✅ Theming system (`applyTheme`, `Theme`, CSS variables)
3. ✅ Multi-app support (infrastructure exists; documented)
4. ✅ Enhanced monitoring (`configureMonitoring`, hooks in tenant operations)

### Phase 4: Polish (Long-term)
1. Comprehensive documentation
2. Storybook for components
3. Performance optimization
4. Security audit

---

## 💡 Honest Assessment

### ✅ **What's Right:**
1. **Separation of concerns is mostly correct** - framework vs. app logic
2. **Reusability is achievable** - can build new apps on this foundation
3. **Type safety** - TypeScript throughout
4. **Multi-tenancy is well-architected** - tenant isolation is solid

### ⚠️ **What Needs Work:**
1. ~~**Incomplete migration**~~ ✅ **COMPLETED** - user management, auth pages, and backend routes moved to `beacon-tenant`
2. ~~**Backend route inconsistency**~~ ✅ **COMPLETED** - users route moved to `beacon-tenant` (invitations remains in backend due to Person model dependency)
3. ~~**No configuration layer**~~ ✅ **COMPLETED** - `configureBeacon` and `BeaconConfig` added
4. ~~**Service layer missing**~~ ✅ **COMPLETED** - `BeaconApiClient` with `checkPermission`, `PageGuard` uses service layer
5. **Documentation gaps** - architecture documentation in progress

### 🎯 **Verdict:**
**The architecture is sound, but incomplete.** The 3-app model is the right approach for:
- ✅ Multi-tenant SaaS
- ✅ Reusable framework
- ✅ Enterprise scalability
- ✅ Maintainability

**Implementation Status:**
1. ✅ Complete the migration (move all tenant-scoped code to `beacon-tenant`) - **DONE**
2. ✅ Add abstraction layers (config, services) - **DONE**
3. 🔄 Document the architecture clearly - **IN PROGRESS** (CONFIG.md added, ARCHITECTURE_ANALYSIS updated)
4. ✅ Establish clear boundaries and contracts - **DONE** (routes in tenant, services abstracted)

---

## 📚 Additional Recommendations

### 1. **Versioning Strategy**
- Use semantic versioning
- `beacon-tenant` and `beacon-app-layout` should be versioned independently
- Apps pin to specific versions
- Breaking changes require major version bumps

### 2. **Testing Strategy**
- Unit tests for `beacon-tenant` (critical infrastructure)
- Integration tests for tenant workflows
- E2E tests for complete user journeys

### 3. **Deployment Strategy**
- `beacon-tenant` and `beacon-app-layout` can be published to private npm (or used as git submodules)
- Apps consume via `package.json` dependencies
- CI/CD ensures compatibility

### 4. **Developer Experience**
- Clear getting started guide
- Example apps
- TypeScript autocomplete for all APIs
- Error messages that guide developers

---

## 🚀 Conclusion

**Your architecture is on the right track.** The 3-app model provides:
- Clear separation of concerns
- Reusability
- Scalability
- Maintainability

**Complete the migration, add abstraction layers, and document everything.** This will be a solid, enterprise-grade multi-tenant framework.
