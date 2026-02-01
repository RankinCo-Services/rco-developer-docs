# How to Create a New App for Beacon (Junior Developer Guide)

Step-by-step instructions for creating a new app that works with the Beacon platform. Choose **Path A** (standalone: your app has its own frontend URL) or **Path B** (in-platform: your app runs inside Beacon’s UI at `/apps/your-app`).

---

## Before You Start

**Get these from your lead or Render/GitHub:**

| What | Example | Where |
|------|---------|--------|
| **App name** (slug) | `my-cool-app` | You pick. Use lowercase, hyphens only. No spaces. |
| **RENDER_API_KEY** | `rnd_xxx...` | [Render Dashboard → Account → API Keys](https://dashboard.render.com/u/settings?add-api-key) |
| **Render workspace ID** | `tea-d5qerqf5r7bs738jbqmg` | RankinCo Services. Your lead can confirm. |

**On your machine:**

- GitHub account with access to **RankinCo-Services** org
- **Git** and **Bash** (Terminal)
- **jq** and **curl** (install with Homebrew if needed: `brew install jq`)

---

## Path A: Standalone App (your own frontend URL)

Your app will have its own URL (e.g. `https://my-cool-app-frontend.onrender.com`) and its own database and API.

### Step 1: Create the repo from the template

1. Open **beacon-app-min** on GitHub:  
   `https://github.com/RankinCo-Services/beacon-app-min`
2. Click the green **Use this template** button → **Create a new repository**.
3. **Do not fork.** Use “Use this template” so the new repo has no shared history.
4. Set:
   - **Owner:** RankinCo-Services  
   - **Repository name:** your app slug (e.g. `my-cool-app`)  
   - **Private** (unless told otherwise)
5. Click **Create repository**. Leave “Add a README” unchecked.

### Step 2: Clone and bootstrap Render

In Terminal (replace `my-cool-app` with your app name and use your actual Render workspace ID if different):

```bash
git clone https://github.com/RankinCo-Services/my-cool-app.git
cd my-cool-app
```

Set your Render API key for this session (or put it in `scripts/.secrets` — see Optional below):

```bash
export RENDER_API_KEY=your_key_here
```

Run the bootstrap script (creates database, API, and frontend on Render):

```bash
./scripts/render-bootstrap-multi-app.sh my-cool-app tea-d5qerqf5r7bs738jbqmg https://github.com/RankinCo-Services/my-cool-app
```

- When prompted for **Internal Database URL**: wait 1–2 minutes after the script creates the DB, then in [Render Dashboard](https://dashboard.render.com) open **my-cool-app-db** → **Info** → copy **Internal Database URL** and paste it. Or press Enter to skip and set it later on the **my-cool-app-api** service.

### Step 3: Push to trigger deploy

```bash
git push origin main
```

Go to [Render Dashboard](https://dashboard.render.com) → your app’s project. Wait for **my-cool-app-api** and **my-cool-app-frontend** to finish deploying. Open the frontend URL (e.g. `https://my-cool-app-frontend.onrender.com`) and confirm you see **Database: connected**.

**Optional (no prompts):** Create `scripts/.secrets` (do not commit) with:

```bash
export RENDER_API_KEY=...
# export DATABASE_URL=...   # optional; script can get from Render
```

Then run the script with `--no-prompt`:

```bash
./scripts/render-bootstrap-multi-app.sh my-cool-app tea-d5qerqf5r7bs738jbqmg https://github.com/RankinCo-Services/my-cool-app --no-prompt
```

---

## Path B: In-Platform App (runs inside Beacon)

Your app’s UI will live inside Beacon at `/apps/my-cool-app`. You only create the app’s **database** and **API**; Beacon’s frontend hosts the UI.

### Step 1: Create the repo from the template

Same as Path A: **Use this template** from **beacon-app-min** → new repo under **RankinCo-Services** with your app name (e.g. `my-cool-app`).

### Step 2: Clone and bootstrap with `--in-platform`

```bash
git clone https://github.com/RankinCo-Services/my-cool-app.git
cd my-cool-app
export RENDER_API_KEY=your_key_here
```

Run the script **with `--in-platform`** (creates only database and API, no frontend):

```bash
./scripts/render-bootstrap-multi-app.sh my-cool-app tea-d5qerqf5r7bs738jbqmg https://github.com/RankinCo-Services/my-cool-app --in-platform
```

- When prompted for **Internal Database URL**: same as Path A (copy from Render → my-cool-app-db → Info → Internal Database URL, or Enter to set later).
- When prompted for **BEACON_FRONTEND_URL**: enter Beacon’s frontend URL (e.g. `https://beacon-frontend-sy4c.onrender.com`). Your lead can give you the exact URL. This is used so your app API allows requests from Beacon (CORS).

### Step 3: Push and note your API URL

```bash
git push origin main
```

After deploy, your app API URL will be something like:  
`https://my-cool-app-api.onrender.com`  
(Check Render → **my-cool-app-api** → URL.) You’ll need this for Beacon.

### Step 4: Add your app to the Beacon repo (code changes)

Someone with access to the **Beacon** repo (you or your lead) must add the in-platform app there. Namespace = app slug (e.g. `my-cool-app`).

1. **API config** — In Beacon repo, edit `frontend/src/config/appApis.ts`:
   - Add your app’s API URL to the `APP_APIS` object (key = namespace, value = API URL).
   - Add a display name to `IN_PLATFORM_APP_DISPLAY_NAMES` (key = namespace, value = label for sidebar).

   Example for `my-cool-app`:

   ```ts
   const APP_APIS: Record<string, string> = {
     'multi-app-test': import.meta.env.VITE_MULTI_APP_TEST_API_URL || '...',
     'my-cool-app': import.meta.env.VITE_MY_COOL_APP_API_URL || 'https://my-cool-app-api.onrender.com',
   }
   export const IN_PLATFORM_APP_DISPLAY_NAMES: Record<string, string> = {
     'multi-app-test': 'Multi-App Test',
     'my-cool-app': 'My Cool App',
   }
   ```

2. **App module and route** — In Beacon repo:
   - Add a folder and page component, e.g. `frontend/src/apps/my-cool-app/MyCoolAppDashboardPage.tsx` (you can copy and adapt from `frontend/src/apps/multi-app-test/`).
   - In `frontend/src/apps/InPlatformAppPage.tsx`, register the component in the `APP_MODULES` object (key = namespace, value = the page component).

3. **Route** — The route `/apps/:appSlug` already exists in Beacon; no change needed if you only add a new namespace and module.

### Step 5: Set environment variables on Render

**Beacon frontend (Render):**

- Service: **beacon-frontend** (or whatever the Beacon frontend service is named).
- Add env var:  
  **Name:** `VITE_MY_COOL_APP_API_URL`  
  **Value:** `https://my-cool-app-api.onrender.com`  
  (Use your actual app API URL. The name is `VITE_` + namespace in SCREAMING_SNAKE_CASE + `_API_URL`.)
- Redeploy Beacon frontend so the new value is baked into the build.

**Your app API (Render):**

- Service: **my-cool-app-api**.
- Ensure **FRONTEND_URL** = Beacon frontend URL (e.g. `https://beacon-frontend-sy4c.onrender.com`). The bootstrap script may have set this if you entered BEACON_FRONTEND_URL; if not, set it in the API service’s environment variables and redeploy.

### Step 6: Register the app in the platform

The app must be registered so it appears in Beacon’s app launcher. **Restarting the Beacon API does not auto-discover new apps** — the backend only seeds apps that are hardcoded in the seeder (today: `psa` and `multi-app-test`). Use one of these:

- **Option A (seed):** Your lead adds the app in Beacon’s `backend/src/utils/permissionSeeder.ts` (same pattern as `multi-app-test`), then restarts/redeploys the Beacon API. After that, the app appears under **Platform Admin → Apps**.
- **Option B (no code change):** A platform admin goes to **Platform Admin → Apps** → **Create app** and enters namespace (e.g. `my-cool-app`), name, launch URL (or leave blank for in-platform), status **Published**.

Then in **Platform Admin → Subscriptions**, assign the app to the tenants that should see it in the launcher. See beacon-app-min [docs/MULTI_APP_RUNBOOK.md](https://github.com/RankinCo-Services/beacon-app-min/blob/main/docs/MULTI_APP_RUNBOOK.md) § “Adding a new app to the Beacon platform”.

### Step 7: Verify

1. Log into Beacon and open the app launcher.
2. Your app should appear; open it.
3. You should see Beacon’s layout with your app’s content at `/apps/my-cool-app` and **Database: connected** (if your page calls the app API’s health endpoint).

---

## Quick Reference

| Path | Script | Creates | Where users open the app |
|------|--------|--------|---------------------------|
| **A: Standalone** | `render-bootstrap-multi-app.sh <app> <owner_id> <repo_url>` | -db, -api, -frontend | App’s own frontend URL |
| **B: In-platform** | Same script with `--in-platform` | -db, -api only | Inside Beacon at `/apps/<namespace>` |

**Render workspace (RankinCo Services):** `tea-d5qerqf5r7bs738jbqmg`

**If the script fails:** Check that `RENDER_API_KEY` is set, that you have access to the GitHub repo and Render workspace, and that the app name uses only lowercase letters and hyphens. If the database URL isn’t ready, you can set `DATABASE_URL` later in Render on the **my-cool-app-api** service and redeploy.

**More detail:**  
- beacon-app-min: [README](https://github.com/RankinCo-Services/beacon-app-min) and [docs/MULTI_APP_RUNBOOK.md](https://github.com/RankinCo-Services/beacon-app-min/blob/main/docs/MULTI_APP_RUNBOOK.md)  
- Beacon: DEPLOYMENT.md (in-platform apps env)
