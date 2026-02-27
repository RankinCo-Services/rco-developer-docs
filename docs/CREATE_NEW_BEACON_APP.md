# How to Create a New App for Beacon (Post-Inversion)

Step-by-step instructions for creating a new app in the **post-inversion** Beacon architecture.

---

## Architecture overview (read this first)

**Post-inversion:** `beacon-tenant` is the deployed shell host. It owns the frontend, auth, layout, and routing for everything. Your new app contributes:

1. **A backend API** — Express + Prisma, its own Postgres DB, deployed as its own Render service.
2. **A UI package** — a React library (`packages/<your-app>-ui/`) that exports pages, navigation, and route definitions. The shell imports this package and mounts your pages into its layout.

Your app repo (cloned from `beacon-app-min`) lives as a **submodule inside `beacon-tenant`** so the shell can resolve the UI package at build time. The `frontend/` directory in beacon-app-min is a standalone dev harness (useful for isolated work), but the shell does not use it — it uses the UI package directly.

**What the shell imports from your UI package:**

| Export | What it is |
|--------|------------|
| `getManifest(basePath)` | Returns `{ navigation, level2Navigation, level3Navigation }` — the nav structure |
| `routeDefinitions` | Array of `{ path: string, component: ComponentType }` the shell mounts as `<Route>` elements |

> **Critical:** `getManifest` must be **defined inline** in your `packages/<app>-ui/src/index.ts`, not re-exported from another file. Rollup won't follow re-exports from a pre-built dist — the build will fail with "not exported". See [INVERSION_SHELL_BUILD_AND_LAYOUT.md](../beacon-tenant/docs/INVERSION_SHELL_BUILD_AND_LAYOUT.md) §1 for the full story.

---

## Before you start

**Get these from your lead:**

| What | Example | Where |
|------|---------|--------|
| **App name** (slug) | `my-cool-app` | You pick. Lowercase, hyphens only, no spaces. |
| **RENDER_API_KEY** | `rnd_xxx...` | [Render Dashboard → Account → API Keys](https://dashboard.render.com/u/settings?add-api-key) |
| **Render workspace ID** | `tea-d5qerqf5r7bs738jbqmg` | RankinCo Services. |
| **PLATFORM_API_URL** | `https://beacon-platform-api.onrender.com` | The live platform API URL. |
| **PLATFORM_INTERNAL_SECRET** | `some-secret` | Shared secret for tenant validation. Ask your lead. |

**On your machine:**

- GitHub account with access to **RankinCo-Services** org
- Git, Bash, `jq`, `curl` (install with `brew install jq` if needed)
- Node.js (same version as the project — check `.nvmrc` in beacon-tenant)

---

## Step 1: Create the app repo from the template

1. Open **beacon-app-min** on GitHub: `https://github.com/RankinCo-Services/beacon-app-min`
2. Click the green **Use this template** button → **Create a new repository**.
3. **Do not fork.** Use "Use this template".
4. Set:
   - **Owner:** RankinCo-Services
   - **Repository name:** your app slug (e.g. `my-cool-app`)
   - **Private**
5. Click **Create repository**.

Clone it:

```bash
git clone https://github.com/RankinCo-Services/my-cool-app.git
cd my-cool-app
git submodule update --init --recursive
```

---

## Step 2: Bootstrap Render (database and API only)

Your app needs a Postgres database and an API service. There is **no separate frontend** — the shell (beacon-tenant) hosts your UI.

```bash
export RENDER_API_KEY=your_key_here
./scripts/render-bootstrap-multi-app.sh my-cool-app tea-d5qerqf5r7bs738jbqmg https://github.com/RankinCo-Services/my-cool-app --in-platform
```

Using `--in-platform` creates only `-db` and `-api` (no frontend service).

- When prompted for **Internal Database URL:** wait 1–2 min, then Render Dashboard → `my-cool-app-db` → Info → copy Internal Database URL.
- When prompted for **BEACON_FRONTEND_URL:** enter the shell's frontend URL (e.g. `https://beacon-inversion-frontend.onrender.com`). This sets CORS on your API.

```bash
git push origin main
git checkout -b development
```

> This initial push to `main` is needed to trigger Render to deploy the bootstrapped API service. After this, all ongoing work is done on the `development` branch (see branch note in Step 9).

Once deployed, set these on your API service in Render:

| Variable | Value |
|----------|-------|
| `PLATFORM_API_URL` | Platform API base URL (e.g. `https://beacon-platform-api.onrender.com`) |
| `PLATFORM_INTERNAL_SECRET` | The shared secret for `/internal/validate-tenant` |

---

## Step 3: Create the UI package

Inside your app repo, create the `packages/my-cool-app-ui/` directory. This is what the shell will import.

The structure mirrors `Beacon/packages/psa-ui/`:

```
packages/
  my-cool-app-ui/
    src/
      index.ts           ← MUST inline getManifest here (not re-export)
      navigation.ts      ← nav helpers (getNavigation, etc.)
      routeDefinitions.tsx
      pages/
        DashboardPage.tsx
    package.json
    tsconfig.build.json
```

**`package.json`** (substitute your app name throughout):

```json
{
  "name": "@beacon-tenant/my-cool-app-ui",
  "version": "0.1.0",
  "description": "My Cool App UI package for the Beacon shell.",
  "type": "module",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "exports": {
    ".": {
      "import": "./dist/index.js",
      "types": "./dist/index.d.ts"
    }
  },
  "files": ["dist"],
  "scripts": {
    "build": "tsc -p tsconfig.build.json"
  },
  "dependencies": {
    "axios": "^1.6.5",
    "lucide-react": "^0.344.0",
    "react-router-dom": "^6.21.1"
  },
  "peerDependencies": {
    "@beacon/app-layout": ">=0.1.0",
    "@beacon/ui": ">=0.1.0",
    "react": ">=18.0.0",
    "react-router-dom": ">=6.0.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.0",
    "react": "^18.2.0",
    "typescript": "^5.3.0"
  }
}
```

**`src/navigation.ts`** — build your nav structure here. Return types must match `NavSection`, `Level2Nav`, `Level3Nav` from `@beacon/app-layout`.

> **Available component library:** Your pages can import from `@beacon/ui` for the full Beacon component library (buttons, badges, cards, tables, KPI strips, blocks). The shell already imports `@beacon/ui/styles/tokens.css` globally — no additional CSS setup needed in your app. The `"@beacon/ui": ">=0.1.0"` peer dependency in the `package.json` above covers this.

**`src/index.ts`** — **inline `getManifest` here, do not re-export it:**

```ts
import { getNavigation, getLevel2Navigation, getLevel3Navigation } from './navigation';
import type { NavSection, Level2Nav, Level3Nav } from '@beacon/app-layout';

export type { MyCoolAppRouteDef } from './routeDefinitions';
export { routeDefinitions as myCoolAppRouteDefinitions } from './routeDefinitions';

// IMPORTANT: define getManifest inline — do not re-export from ./navigation.
// Rollup requires a direct export in the built entry file.
export interface MyCoolAppManifest {
  navigation: NavSection[];
  level2Navigation: Level2Nav[];
  level3Navigation: Level3Nav[];
}

export function getManifest(basePath = ''): MyCoolAppManifest {
  return {
    navigation: getNavigation(basePath),
    level2Navigation: getLevel2Navigation(basePath),
    level3Navigation: getLevel3Navigation(basePath),
  };
}
```

**`src/routeDefinitions.tsx`** — maps path segments (relative to your app base) to page components:

```tsx
import type { ComponentType } from 'react';
import DashboardPage from './pages/DashboardPage';

export interface MyCoolAppRouteDef {
  path: string;
  component: ComponentType;
}

export const routeDefinitions: MyCoolAppRouteDef[] = [
  { path: '',         component: DashboardPage },  // matches /my-cool-app
  { path: '*',        component: DashboardPage },  // catch-all
];
```

Build the package (from the `packages/my-cool-app-ui/` directory):

```bash
cd packages/my-cool-app-ui && npm install && npm run build
```

Commit everything:

```bash
cd ../../ && git add packages/ && git commit -m "feat: add my-cool-app-ui package"
git push origin development
```

---

## Step 4: Add as a submodule in beacon-tenant

In your local clone of **beacon-tenant** (from `~/GitHub/beacon-tenant`):

```bash
cd ~/GitHub/beacon-tenant
git submodule add https://github.com/RankinCo-Services/my-cool-app.git my-cool-app
git submodule update --init my-cool-app
git add .gitmodules my-cool-app
git commit -m "chore: add my-cool-app submodule"
```

---

## Step 5: Register the UI package in the shell

From beacon-tenant root, make these four changes to `apps/shell/`:

### 5a. `apps/shell/package.json`

Add the dependency pointing to your package in the submodule:

```json
"@beacon-tenant/my-cool-app-ui": "file:../../my-cool-app/packages/my-cool-app-ui",
```

Then reinstall:

```bash
cd apps/shell && npm install
```

### 5b. `apps/shell/src/platformNavigation.ts`

Add a nav section entry for your app:

```ts
import { LayoutDashboard } from 'lucide-react'; // pick an appropriate icon

// Add to platformNavigation array:
{
  id: 'my-cool-app',
  name: 'My Cool App',
  path: '/my-cool-app',
  icon: LayoutDashboard,
  tabs: [{ id: 'my-cool-app', label: 'My Cool App', path: '/my-cool-app' }],
  description: 'My Cool App description',
},
```

### 5c. `apps/shell/src/PlatformLayout.tsx`

Import your manifest and add a branch in `useMergedNav()`:

```ts
import { getManifest as getMyCoolAppManifest } from '@beacon-tenant/my-cool-app-ui';

// Inside useMergedNav(), before the PSA branch:
if (pathname.startsWith('/my-cool-app')) {
  const manifest = getMyCoolAppManifest('/my-cool-app');
  const prefixed = prefixManifestIds('my-cool-app', manifest.navigation, manifest.level2Navigation, manifest.level3Navigation);
  return {
    navigation: prefixed.navigation,
    level2Navigation: [...platformLevel2Navigation, ...prefixed.level2Navigation],
    level3Navigation: [...platformLevel3Navigation, ...prefixed.level3Navigation],
  };
}
```

### 5d. `apps/shell/src/App.tsx`

Import your route definitions and mount them under `TenantAuthGuard` + `PlatformReadyGate`:

```tsx
import { myCoolAppRouteDefinitions, type MyCoolAppRouteDef } from '@beacon-tenant/my-cool-app-ui';

// Inside the <Route element={<TenantAuthGuard><PlatformReadyGate /></TenantAuthGuard>}> block,
// alongside the psa and grc routes:
{myCoolAppRouteDefinitions.map((def: MyCoolAppRouteDef, idx) => {
  const path = def.path === '' ? 'my-cool-app' : def.path === '*' ? 'my-cool-app/*' : `my-cool-app/${def.path}`;
  const Component = def.component;
  return <Route key={`my-cool-app-${path}-${idx}`} path={path} element={<Component />} />;
})}
```

---

## Step 6: Add your package to the shell's Tailwind config

In `apps/shell/tailwind.config.js`, add your package source so Tailwind generates the classes your pages use:

```js
content: [
  './index.html',
  './src/**/*.{js,ts,jsx,tsx}',
  '../../packages/tenant-ui/src/**/*.{js,ts,jsx,tsx}',
  '../../beacon-app-layout/src/**/*.{js,ts,jsx,tsx}',
  '../../Beacon/packages/psa-ui/src/**/*.{js,ts,jsx,tsx}',
  '../../beacon-grc/packages/grc-ui/src/**/*.{js,ts,jsx,tsx}',
  '../../my-cool-app/packages/my-cool-app-ui/src/**/*.{js,ts,jsx,tsx}', // ← add this
],
```

---

## Step 7: Register the app in the platform

The app must exist in the platform DB so it appears in the app launcher and subscriptions work.

Add it to the permission seeder in the **platform backend** (`packages/platform-server/src/...`), following the same pattern as `psa` and `grc`. Ask your lead if you're not sure where the seeder is. After the seeder runs (redeploy), the app appears under **Platform Admin → Apps**.

Then in **Platform Admin → Subscriptions**, assign the app to the tenants that should see it.

---

## Step 8: Set env vars on Render

**Shell (beacon-inversion-frontend):**

Add an env var for your app's API:

| Name | Value |
|------|-------|
| `VITE_MY_COOL_APP_API_URL` | `https://my-cool-app-api.onrender.com` |

The name pattern is `VITE_` + app slug in `SCREAMING_SNAKE_CASE` + `_API_URL`. Redeploy the shell after adding it.

**App API (my-cool-app-api):**

| Name | Value |
|------|-------|
| `FRONTEND_URL` | Shell frontend URL (e.g. `https://beacon-inversion-frontend.onrender.com`) |
| `PLATFORM_API_URL` | Platform API URL |
| `PLATFORM_INTERNAL_SECRET` | Shared secret for tenant validation |

---

## Step 9: Commit and deploy

In beacon-tenant, commit the submodule ref and shell changes from your `development` branch, then sync and deploy:

```bash
cd ~/GitHub/beacon-tenant
git add apps/shell my-cool-app .gitmodules
git commit -m "feat: add my-cool-app to shell"
git push origin development

# Sync all submodules to development and trigger Render deploy
./scripts/sync-all-submodules.sh development
```

> **Branch note:** All work is done on `development`. `./scripts/sync-all-submodules.sh development` syncs submodules (Beacon, beacon-app-layout, beacon-grc) to their latest `development` commits, commits the updated submodule refs in beacon-tenant, and pushes — triggering a Render build.

Monitor the build on Render — `scripts/render-build.sh` inits the submodule and builds the shell.

---

## Step 10: Verify

1. Log into Beacon — the shell URL.
2. Your app should appear in the sidebar and app launcher.
3. Navigate to `/my-cool-app` — you should see your `DashboardPage` inside the Beacon layout.

---

## After initial setup: ongoing development

**When you make UI changes in your app repo:**

1. Build the UI package: `cd packages/my-cool-app-ui && npm run build`
2. Commit and push the app repo.
3. In beacon-tenant, sync submodules and deploy:
   ```bash
   cd ~/GitHub/beacon-tenant
   ./scripts/sync-all-submodules.sh development
   ```

**Local dev:**

Run the beacon-tenant shell locally — it resolves your UI package from the local submodule via the `file:` path. No separate frontend server needed.

```bash
# Terminal 1 — app backend
cd ~/GitHub/my-cool-app/backend && npm install && npm run dev

# Terminal 2 — shell (resolves your UI package from submodule)
cd ~/GitHub/beacon-tenant/apps/shell && npm install && npm run dev
```

Set `apps/shell/.env.local` with:

```
VITE_CLERK_PUBLISHABLE_KEY=pk_test_...
VITE_API_URL=http://localhost:3001        # platform API (if running locally)
VITE_MY_COOL_APP_API_URL=http://localhost:3000
```

---

## Quick reference

| Step | What | Where |
|------|------|-------|
| 1 | Create repo from template | GitHub — beacon-app-min |
| 2 | Bootstrap Render (DB + API, `--in-platform`) | Terminal — bootstrap script |
| 3 | Create `packages/<app>-ui/` | Your app repo |
| 4 | Add submodule | `beacon-tenant` repo |
| 5 | Register in shell (package.json, PlatformLayout, App, platformNavigation) | `beacon-tenant/apps/shell/` |
| 6 | Add Tailwind content path | `beacon-tenant/apps/shell/tailwind.config.js` |
| 7 | Seed app in platform DB | Platform backend seeder |
| 8 | Set env vars on Render | Render Dashboard |
| 9 | Commit + deploy | `beacon-tenant` — `./scripts/sync-all-submodules.sh development` |

**Render workspace (RankinCo Services):** `tea-d5qerqf5r7bs738jbqmg`

**Deploy flow:** All work on `development`. Deploy to dev: `./scripts/sync-all-submodules.sh development` (syncs submodules + pushes → Render auto-deploys). Promote to production: `./scripts/production-build-check.sh` then `./scripts/promote-to-production.sh --execute "message"` (merges `development` → `main` across all repos).

**getManifest must be inlined** in the package's `src/index.ts`. Do not re-export it from a sub-file — Rollup won't resolve it from a pre-built dist entry.

**Reference docs:**
- [INVERSION_SHELL_BUILD_AND_LAYOUT.md](../beacon-tenant/docs/INVERSION_SHELL_BUILD_AND_LAYOUT.md) — build gotchas and Rollup fix
- [PLATFORM_APP_CONTRACT.md](../beacon-tenant/docs/PLATFORM_APP_CONTRACT.md) — platform ↔ app API (tenant validation, audit ingest, cache invalidation)
- [beacon-app-min README](https://github.com/RankinCo-Services/beacon-app-min) — backend/Prisma setup, migration scripts
