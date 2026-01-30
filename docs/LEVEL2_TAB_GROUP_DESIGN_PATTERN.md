# Level-2 Tab Group Design Pattern

This document describes the **second-level tab group** (the horizontal row of tabs directly under the breadcrumb) and how to implement it in Beacon and other RankinCo apps that use **@beacon/app-layout**.

## Design pattern

The main content area uses a consistent layout:

1. **Breadcrumb bar** — Top of the content area; shows section and active tab (e.g. `Administration > Company Information`, `Analytics > Overview`).
2. **Level-2 tab row** — Horizontal row of tabs directly under the breadcrumb (e.g. Company Information | Reference | Sales | People | … or Overview | Sales | Operations | Financials). This is the **TopTabBar** from the layout; it is **not** rendered by the page component.
3. **Content** — The selected tab’s content (rendered by the route’s component).

**Important:** The tab row is rendered by the **layout** when the current path matches a **level2Navigation** entry. The page for that section should render only an `<Outlet />`; the actual tab content is rendered by nested routes.

### Examples in Beacon

- **Administration > Settings** — Breadcrumb: `Administration > Company Information` (or the active tab). Tab row: Company Information, Reference, Sales, People, Operations, Finance, Billing, Custom Fields. Some tabs (Sales, People) have a dropdown (level-3) for sub-pages (e.g. Stages, Departments).
- **Analytics > Executive** — Breadcrumb: `Analytics > Overview` (or active tab). Tab row: Overview, Sales, Operations, Financials.
- **Operations > People** — Tab row: Dashboard, People, Teams, Team Overview, Resource Planning, Utilization, Scheduling.
- **Finance > Accounting** — Tab row: Chart of Accounts, General Ledger, Balance Sheet, Income Statement.

## How it is implemented

### 1. Layout (beacon-app-layout)

- **MainContent** — Renders `Breadcrumbs` then `<main>{children}</main>`.
- **AppLayout** — Renders `MainContent` with:
  - `{level2Tabs && level2Tabs.length > 0 && <TopTabBar />}` — The level-2 tab row, only when `getLevel2Nav(level2Navigation, location.pathname)` returns tabs.
  - `<Outlet />` — The current route’s component (e.g. a page that renders `<Outlet />` for nested tab content).

So the visual order is: **Breadcrumbs → TopTabBar (if level2 match) → Outlet**.

- **TopTabBar** — Reads `level2Navigation` and `level3Navigation` from `NavigationContext`. For the current path it calls `getLevel2Nav(level2Navigation, pathname)`. If there is a match, it renders a tab for each entry (Link or button with dropdown). Tabs with `hasMenu` and matching `level3Navigation` show a dropdown (e.g. Sales → Stages, People → Departments).
- **Breadcrumbs** — Uses `getCurrentSection(navigation, pathname)` for the first crumb, then `getLevel2Nav` and the active level-2 tab for the second crumb (e.g. `Analytics` > `Overview`).

### 2. App navigation config (e.g. Beacon `config/navigation.ts`)

**level2Navigation** is an array of `{ sectionPath, tabs }`:

- **sectionPath** — Path prefix that activates this tab group (e.g. `/administration/settings`, `/analytics/executive`). When `pathname.startsWith(sectionPath)`, this entry is used.
- **tabs** — Array of `NavTab`: `{ id, label, path, icon?, activePaths?, hasMenu? }`. Each tab links to `path`; if `hasMenu` is true and there is a matching **level3Navigation** entry for that tab’s path, the tab shows a dropdown.

**level3Navigation** (optional) — Array of `{ parentPath, tabs }` for dropdown sub-menus:

- **parentPath** — Path of the level-2 tab that gets the dropdown (e.g. `/administration/settings/sales`).
- **tabs** — Sub-items (e.g. `{ id: 'stages', label: 'Stages', path: '/administration/settings/sales/stages' }`).

### 3. Routes (e.g. Beacon `App.tsx`)

For a section that uses the level-2 tab group:

1. **Parent route** — Renders a **wrapper component that only renders `<Outlet />`** (e.g. `SettingsPage`, `ExecutiveDashboardPage`). Do **not** put a title or custom tab row here; the layout provides the tab row.
2. **Index route** — Redirect to the default tab (e.g. `<Route index element={<Navigate to="/analytics/executive/overview" replace />} />`).
3. **Nested routes** — One route per tab path, each rendering the tab’s content component (e.g. `CompanyInformationTab`, `ExecutiveOverviewTab`).

Example (Executive Dashboard):

```tsx
<Route path="executive" element={<ExecutiveDashboardPage />}>
  <Route index element={<Navigate to="/analytics/executive/overview" replace />} />
  <Route path="overview" element={<ExecutiveOverviewTab />} />
  <Route path="sales" element={<ExecutivePlaceholderTab title="Sales" />} />
  <Route path="operations" element={<ExecutivePlaceholderTab title="Operations" />} />
  <Route path="financials" element={<ExecutivePlaceholderTab title="Financials" />} />
</Route>
```

`ExecutiveDashboardPage` is just:

```tsx
export default function ExecutiveDashboardPage() {
  return <Outlet />
}
```

### 4. Tab content components

Each nested route renders the content for that tab (e.g. a heading, description, and main content). The tab row and breadcrumb are already provided by the layout; the component does **not** render tabs.

## Summary: Adding a new level-2 tab group

1. **Config** — In `level2Navigation`, add an entry with `sectionPath: '/your/section/path'` and `tabs: [{ id, label, path, icon?, ... }]`. Optionally add `level3Navigation` entries for dropdowns (`parentPath` = tab path, `tabs` = sub-items).
2. **Routes** — Add a parent route for that path whose element is a component that renders only `<Outlet />`. Add an index redirect to the default tab path. Add nested routes for each tab path.
3. **Components** — Implement one component per tab (the content for that route). Do not render a custom tab row; use the layout’s TopTabBar.

This keeps the layout consistent with **Administration > Settings** and **Analytics > Executive**: breadcrumb → same TopTabBar row → content.
