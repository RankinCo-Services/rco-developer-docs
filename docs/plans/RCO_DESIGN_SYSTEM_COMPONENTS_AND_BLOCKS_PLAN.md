# RCO Design System: Components, Wrappers, Blocks, and Styling Consistency

**Purpose:** Capture design decisions for a shared RCO component and block system on the Beacon platform. For later review and implementation.

**Plan key (Giga):** `rco-design-system-components-and-blocks`

---

## 1. RCO-* components (single definition)

- **Where:** Define in **beacon-app-layout** (or shared RCO design-system layer it owns). One definition for all RCO apps.
- **Examples:** RCO-KPICard, RCO-MiniTable, RCO-RadialChart (and wrappers like RCO-DetailPanelWrapper).
- **Contract:** Standardized required and optional props that the system can be developed to utilize over time.
- **`type` prop:** Require a **generic `type` (string)**, not an enum. App developer chooses values (e.g. `"finance"`, `"project-health"`, `"audit"`). Platform can key off type for permissions, theming, analytics, etc. without locking apps into a fixed set of values.
- **Benefits:** Single source of truth; consistent look and behavior; app gets customization via type and data; platform can add behaviors that use the same props later.

---

## 2. Wrappers (same pattern)

- **Idea:** Wrappers (e.g. detail panel, sheet) expose **standard props and styling hooks** the platform uses; the **wrapped content** is app-defined.
- **Contract:** Platform defines the wrapper API; app supplies children and optional config. System interacts with the wrapper via the contract; styling comes from app layout tokens/globals.
- **No second path:** Use RCO-* wrappers for panels/sheets so apps don't hand-roll their own and drift.

---

## 3. Styling consistency across RCO apps

- **Single source of truth:** Layout and design-system components (including RCO-*) live in **beacon-app-layout**. All RCO apps consume them; they don't reimplement.
- **Tokens / globals:** App layout defines tokens (colors, spacing, radius, shadows, type scale). RCO-* components use only those; no ad hoc values or app-level overrides of component styles.
- **"Layout wins" rule:** Global styles from app layout must win. Apps don't override RCO-* or app-layout component styles; they use props and content.
- **RCO-* as the standard:** Cards, panels, tables, etc. are RCO-* (or app-layout) components. Document and review so new work uses them instead of custom Tailwind compositions.
- **Shared build / versioning:** Apps depend on the same app layout version and same globals so styling runtime is consistent.

---

## 4. RCO-Block (composite "section" components)

- **Definition:** A **block** is a predefined composition of RCO components: fixed layout + which components + data mapping. App developer uses one component (e.g. `RCO-Block-MiniDashboard`) and passes **data** (and optional config).
- **Example:** RCO-Block-MiniDashboard = 3 RCO-KPICards in a row + RCO-RadialChart + RCO-MiniTable. App supplies kpis, chartData, tableData via props.
- **Composition:** Block **composes** RCO-KPICard, RCO-MiniTable, etc.; it does not duplicate their styling or logic. Block owns layout and mapping data → inner components.
- **Data contract:** Each block defines its props (required/optional data + config). Document so app developers know exactly what shape to pass.
- **Type / standard props:** Blocks can have the same kind of `type` (and other standard props) so the system can treat the whole block consistently (permissions, theming, analytics).
- **Naming:** RCO-Block-MiniDashboard, RCO-Block-ExecutiveSummary, etc. — named patterns for discovery and reuse.
- **Scope:** Start with **fixed-composition** blocks (data-only, no slots). Add variants or optional slots later if use cases require it.

---

## 5. RCO-KPICard props (draft)

From follow-up discussion: required/optional props, label vs instance label, and generic props (help, source, empty state). Apply same patterns to other RCO components where relevant.

### 5.1 Required props

| Prop | Type | Purpose |
|------|------|---------|
| **type** | `string` | App-defined; system can use for theming, permissions, analytics. |
| **label** | `string` | User-facing text on the card (e.g. "Revenue YTD"). Same label can appear on multiple pages. |
| **instanceLabel** | `string` | **Human-readable** identifier for *this specific instance*. Use when the same KPI appears in more than one place (e.g. "Revenue YTD" on Finance Dashboard vs Project Summary). Enables docs, support, and tooling to refer to "the Revenue YTD on the Finance Dashboard" unambiguously. |
| **value** | `string \| number \| null` | Main KPI value to show. `null` = loading or no data (card can show skeleton/placeholder). |

**id:** Optional machine-friendly unique key (DOM, a11y, analytics). Component can derive from `instanceLabel` (e.g. slug) if not provided.

### 5.2 Optional — display and behavior

| Prop | Type | Purpose |
|------|------|---------|
| **subtitle** | `string` | Extra context under the label (e.g. "Fiscal 2024"). |
| **unit** | `string` | Display unit: `"$"`, `"%"`, `"hrs"`. |
| **trend** | `'up' \| 'down' \| 'neutral'` | Direction for trend indicator. |
| **trendLabel** / **trendValue** | `string` | e.g. "+12%" or "vs. last month". |
| **href** | `string` | Makes the card clickable. |
| **loading** | `boolean` | Show skeleton; ignore value when true. |
| **error** | `string` | Error state message or code. |
| **variant** | `string` | e.g. `"default" \| "compact" \| "highlight"`. |

### 5.3 Optional — help and explanation

| Prop | Type | Purpose |
|------|------|---------|
| **helpText** | `string` | Shown when user clicks a help (?) icon. Use for: formula, short definition, "what this metric means," or data explanation. |
| **helpTitle** | `string` | Optional heading for the help content when helpText is long. |

### 5.4 Optional — provenance and empty state

| Prop | Type | Purpose |
|------|------|---------|
| **sourceLabel** / **dataSource** | `string` | Where the data comes from or scope (e.g. "Project time entries," "As of close 2024-01-15"). Can appear under value or in help. |
| **asOf** / **lastUpdated** | `string` or ISO date | "Data as of" or last refresh; for display and cache/refresh logic. |
| **emptyStateMessage** | `string` | When value is null/empty (and not loading/error), what to show (e.g. "No data for this period"). |

### 5.5 Optional — system and a11y

| Prop | Type | Purpose |
|------|------|---------|
| **ariaLabel** | `string` | Override for screen readers when label + value is insufficient. |
| **className** | `string` | Layout/spacing only (e.g. margin, grid); not for overriding card look (layout wins). |
| **metadata** / **analyticsContext** | `object` | Optional key/value for analytics or tooling. |

### 5.6 Type (accent color) and accounting-basis badge

- **type** (required, §5.1) drives the card’s **accent color**: e.g. Financial, Operations, Projects, Sales, People, Alerts. App-defined string; design system maps type → color (top bar, chart, trend). No enum — app chooses values.
- **accountingBasis** (optional): Small badge indicating accounting basis. Values: `'gl'` (display "G/L") or `'mgmt'` (display "MGMT" for management accounting). Omit or `null` = no badge. Shown near the label/title (e.g. pill next to "Revenue Growth" or "Team Utilization").

---

## 6. RCO-KPICard: base and variants

**Decision:** RCO-KPICard is a **component family**: a shared **base** plus multiple **variants** that extend it. Implementation approach: **Option A — base with a slot** (see below). No code changes until examples are gathered; this section documents the design for the next implementation step.

### 6.1 Why components (not wrappers)

- KPI cards have a **fixed, repeated structure**: label, value, optional subtext/trend (or chart, or chart+table). Same slots everywhere, with optional behavior (click, loading, error). That is **component territory**.
- If cards were arbitrary content (sometimes a number, sometimes a chart, sometimes custom markup with no common shape), a **wrapper with children** would be better. Our usage is the opposite: consistent slots and optional behavior → implement as components.

### 6.2 Multiple variants

We expect several RCO-KPICard variants, not one fixed layout:

- **Default / trend:** label, value, subtext, trend indicator (current pattern).
- **With radial chart:** label, value, plus a radial chart instead of (or in addition to) trend.
- **Size:** small, medium, large — can apply to any variant.
- **With chart + table:** label, value, plus a chart and a small table (e.g. dashboard tile).

So we need a concept of an **RCO-KPICard base** that we can extend with different layouts/variants.

### 6.3 Base = shared contract + shell + one slot

- **Base RCO-KPICard** provides:
  - **Contract:** Shared props (e.g. from §5: type, label, instanceLabel, value, loading, error, size, etc.).
  - **Shell:** Card container, label, primary value (and shared behavior: loading skeleton, error state, click/href). No assumption about what goes in the “secondary” area.
  - **One slot:** A single area for “everything else” (trend, chart, chart+table, or nothing). The base does not render that content; variants do.

- **Variants** = different uses of the base:
  - Each variant is a thin component that uses the base and **fills the slot** with different content (trend, radial chart, chart+table).
  - **Size** (sm / md / lg) is a prop on the base so all variants get it without duplication.

### 6.4 Option A: base with a slot (chosen approach)

- **KpiCardBase** (internal or exported as primitive) renders: card container (size-aware), label, value (with loading/error), and a **secondary slot** (e.g. `secondaryContent` or reserved `children` for that area only).
- **Variant components** compose the base and pass different content into the slot:
  - **KpiCard** (default) → base + trend in the slot.
  - **KpiCardWithRadialChart** → base + radial chart in the slot.
  - **KpiCardWithChartAndTable** → base + chart + table in the slot.
- **Size** is a prop on the base (e.g. `size: 'sm' | 'md' | 'lg'`), so all variants support small/medium/large.
- **Benefits:** Base stays small and stable; each variant is a focused component; new variants (e.g. sparkline-only) are added by new components that reuse the base, not by branching inside one large component.

### 6.5 Alternative not chosen: single component with `variant` prop

- One `<KpiCard variant="default" | "radialChart" | "chartAndTable"" />` with variant-specific optional props. Simpler API (one import) but the component grows and branches for every variant; harder to maintain. We prefer Option A for clarity and extensibility.

### 6.6 Next step

- Document complete. **Implementation:** Option A (base with slot) in beacon-app-layout. Proceed once examples are available for the next prompt.

### 6.7 Base RCO-KPICard example (reference)

**Location in app:** Executive Dashboard → **Sales Dashboard**.

**Visual spec (base variant only — no secondary content):**

- **Container:** White background, subtle border/shadow, generous padding. Clean, minimal card.
- **Label:** Single line, left-aligned (e.g. "Total Pipeline Value"). Dark gray, standard body size, regular weight. Uses the “label” slot.
- **Value:** Single line below the label (e.g. "$0"). Larger, bold, dark gray/black. Uses the “value” slot. Primary visual focus.
- **Secondary slot:** Empty for this base example — no subtext, trend, chart, or icon. Ample space to the right; variants will fill this area when needed.

**Screenshot reference:** `.cursor/projects/Users-matt-GitHub-Beacon/assets/image-05311ba7-cca6-43db-9bd5-e634529f1cc2.png` (base KPI card: label + value only).

Use this as the implementation reference for the base shell (container + label + value + empty secondary slot). Variants add content into the secondary slot.

### 6.8 PSA as reference only; additional examples and inferred props

**PSA reference-only rule (Beacon):** Per `.cursor/rules/psa-reference-only.mdc`, the **PSA repo** is **reference only** for Beacon. Do **not** copy code, UI, or styling from PSA into Beacon. Use PSA to understand *what* and *why* (features, business rules, patterns); then implement in Beacon’s stack (beacon-app-layout, Beacon services). Refactor intent into Beacon’s architecture — do not copy.

**Confirmation (instructions):** PSA = reference only. Do not copy code, UI, or API usage. Use PSA to learn *what* and *why*; implement in Beacon's stack and design system. Refactor intent only.

**Universal RCO-KPICard props (all variants):** Every card has **type** (e.g. `"Financial"`, `"Operations"`, `"Projects"`, `"Sales"`, `"Risks"`) — **sets accent color**. Optional **accountingBasis**: `'gl'` | `'mgmt'` for **G/L vs MGMT badge**; not every card shows it (e.g. Open Risks has no badge).

**Reference locations in PSA (for understanding only):** KPI card patterns appear in e.g. `src/components/ui/KPICard.jsx`, `src/pages/SalesReports.jsx`, `src/pages/IncomeStatement.jsx`, `src/pages/ProjectRisks.jsx`, `src/pages/TeamUtilization.jsx`, `src/components/utils/cardCategories.jsx` (category keys: FINANCIAL, SALES, PROJECT_MANAGEMENT, PEOPLE, ALERTS, etc.). PSA uses `category` to drive colors; RCO uses `type` (string) to drive accent color.

**Additional example screenshots (variant reference):**

| Example | Description | Screenshot (Beacon Cursor assets) |
|--------|-------------|------------------------------------|
| Revenue Growth (full) | Icon, title, description, value, trend, accent/progress bar, status text, action link, line/area chart, chart title. Badge: G/L. | `image-8aae354c-18dc-429e-ac48-dea473518dc5.png`, `image-68da774d-ab76-4c80-8872-fe6b2aa7e969.png` |
| Team Utilization | Title, badge MGMT, value, trend text (vs target), subtext (e.g. "Monthly"), purple accent (top bar + chart), line chart. Info icon. | `image-03adc0aa-ac51-4373-ae3c-30e52b5f91e9.png` |
| Open Risks | Red top accent, title "Open Risks", value "7", subtext "needs attention", info icon. No badge. | `image-80e1b7ad-6f52-45ca-af4c-57d726059511.png` |
| Summary Stats | Revenue Growth card (G/L badge, icon, description, value, trend, status bar, status + action link, line chart, chart title) next to "Monthly Data" table (Month, Revenue, Expenses, Net). | `image-68da774d-ab76-4c80-8872-fe6b2aa7e969.png` |

**Inferred props from images + PSA (for RCO-KPICard contract):**

- **type** — Sets accent color (e.g. Financial, Operations, Projects, Sales, Alerts/Risks). Already in §5.1; §5.6 clarifies accent.
- **accountingBasis** — `'gl'` \| `'mgmt'` for G/L or MGMT badge. §5.6.
- **label** / **title** — User-facing card title. §5.1.
- **value** — Main metric. §5.1.
- **subtext** / **subtitle** — e.g. "Monthly", "needs attention", "Year to Date". §5.2.
- **description** — Longer text under title (e.g. "Percentage increase in revenue vs. prior period"). Can align with subtitle or a dedicated prop.
- **trend** — Direction: up / down / neutral. §5.2.
- **trendLabel** / **trendValue** — e.g. "+12%", "75% vs target (75%)". §5.2.
- **icon** — Optional icon (e.g. $ for revenue). Not yet in §5; add as optional.
- **statusText** — e.g. "On track", "Strong momentum". Variant/secondary slot.
- **actionLink** / **actionText** + **onActionClick** or **href** — e.g. "Continue current strategies", "Maintain current performance". Variant/secondary slot.
- **accentBar** / **progressBar** — Optional thin bar (e.g. progress or status). Variant/secondary slot.
- **chartData** + **chartTitle** + **chartStatusText** — For variants with chart in secondary slot. Variant-specific.
- **showInfoIcon** / **helpText** — Info (i) icon and tooltip. §5.3 (help).

Base shell (§6.3) owns: type (accent), accountingBasis (badge), label, value, loading, error, optional subtext, optional icon, optional help. Variants (trend, chart, status/action, progress bar) fill the secondary slot with these optional elements; implement via Option A (base + slot).

---

### 6.9 RCO-InfoCard

**Purpose:** Show information relevant to the user in a card (e.g. "Critical Alerts", "Priority Actions", "Overdue Invoices", "Upcoming Tasks"). Each card has a title, optional icon, optional accent color, and a list of items; each item is clickable and opens an item or a page.

**Contract (app layout styling):**
- **title** (required): Card header label (e.g. "Critical Alerts", "Priority Actions").
- **items** (required): Array of `{ label: string; href?: string; onClick?: () => void }`. Each item is rendered as a clickable row; either `href` (navigate) or `onClick` (action).
- **icon** (optional): Header icon (e.g. AlertTriangle, Target). When present, uses accent color from accent class.
- **accentColor** (optional): Same pattern as KpiCard — `undefined` = default accent class, `null` = no accent, `string` = class suffix (e.g. `"alerts"`, `"actions"`). Define `.info-card-accent-{suffix}` in globals with `--info-card-accent`. Color is optional; card can be neutral.
- **type** (optional): App-defined string for semantics/analytics.

**Styling:** All styling in beacon-app-layout globals.css (no inline styles). Card uses app layout tokens (border, background, typography). Accent provides optional top bar/tint when present.

**Implementation:** InfoCard component in beacon-app-layout with Storybook stories (Critical Alerts, Priority Actions, Neutral, AccentViaSuffix). Reference image: `.cursor/projects/Users-matt-GitHub-Beacon/assets/image-4ab54b59-f695-48de-88d5-5164863992a7.png` (two cards: Critical Alerts with red accent, Priority Actions with blue accent; final UI uses app layout styling).

---

### 6.10 RCO-GraphCard

**Purpose:** Card wrapper for any graph type (line, bar, horizontal bar, area, etc.). Used for dashboards such as "Project Health", "Revenue by segment", "Revenue & hours trend", "By customer (top 10)". The **app supplies the chart as `children`**; GraphCard provides the shell (header, optional progress/status/footer) and applies size and graph-type classes so **all styling lives in global CSS**.

**Tiered props:**
- **size:** `sm` | `md` | `lg` | `xl` — Controls padding, typography scale, and content min-height via `.graph-card-size-{size}` in globals.
- **graphType:** `line` | `bar` | `barHorizontal` | `area` | `default` — Chart container gets `.graph-card-chart-type-{type}`; globals set CSS variables (`--graph-line-stroke`, `--graph-bar-fill`, `--graph-fill`, `--graph-grid`) so chart libraries (e.g. Recharts) or placeholder SVGs can use `var(--graph-*)` and styling is consistent per type. Optional variant (e.g. `.graph-card-chart-type-alt`) can override bar color (e.g. orange for horizontal bar).
- **accentColor** / **type:** Same pattern as KpiCard/InfoCard — optional top accent bar and icon tint via `.graph-card-accent-*` and `.graph-card-has-accent`.

**Optional slots:** title, subtitle, value, icon, progress bar (0–1, rendered with class-based width steps in globals; no inline style), statusText + actionLabel + onActionClick, footerLeft/footerRight, headerAction.

**Graph styling per type:** In beacon-app-layout `globals.css`, each `.graph-card-chart-type-*` defines variables (e.g. line: `--graph-line-stroke`, `--graph-fill`; bar: `--graph-bar-fill`; area: same as line with stronger fill). Apps (or Storybook placeholders) use these variables so all graph visuals are driven by globals.

**Implementation:** GraphCard in beacon-app-layout; size and chart-type classes and progress percentage classes (e.g. `.graph-card-progress-pct-0` … `.graph-card-progress-pct-100` in 5% steps) in globals. Stories demonstrate line, bar, horizontal bar, and area with `var(--graph-*)` in placeholder charts.

---

## 7. Component registry: Storybook and Dev tools (hosted by beacon-tenant)

**Decision:** No separate static site for the component catalog. **beacon-app-layout** contains Storybook (stories for RCO wrappers, components, blocks). **beacon-tenant** builds Storybook from app layout during its own build, copies the static output into the shell’s public assets, and serves it at a path. Platform admins reach it via a **Dev tools** item in the platform admin nav.

**Flow:**
1. Storybook lives in **beacon-app-layout** (config, preview, stories). Build command: `npm run build-storybook` → outputs `storybook-static/`.
2. **beacon-tenant** build (or pre-build step) runs that build from app layout (submodule or dependency), then copies `storybook-static/` into the shell’s `public/` (e.g. `public/design-system/`) so the same deployment serves the catalog at e.g. `/design-system`.
3. **Dev tools** in platform admin: new nav item and route (e.g. `/platform-admin/dev-tools`). The Dev tools page iframes or links to the catalog path so one click from platform admin opens the catalog.
4. **App layout** adds the “Dev tools” nav entry in `PlatformAdminSidebar` so any shell using app layout gets it.

**Benefits:** One deploy (beacon-tenant); no extra Render service; catalog version always matches the app layout version the shell uses.

---

## 8. Implementation list — Component registry (Storybook + Dev tools)

### 8.1 beacon-app-layout

- [x] Add Storybook (React + Vite): dependencies, `.storybook/main.ts`, `.storybook/preview.ts`.
- [x] In preview, import app layout `globals.css` (and add Tailwind/PostCSS for Storybook build if needed).
- [x] Mock or provide minimal context for peer deps (tenant-ui, Clerk) in preview so components render.
- [x] Add at least one story (e.g. `Button.stories.tsx`) to verify run and build.
- [x] Scripts: `"storybook": "storybook dev -p 6006"`, `"build-storybook": "storybook build"`. `.gitignore`: `storybook-static/`.
- [ ] Add “Dev tools” nav item in `PlatformAdminSidebar` (path `/platform-admin/dev-tools`, icon e.g. Wrench).

### 8.2 beacon-tenant

- [x] Build integration: in shell build (or a pre-build script), build Storybook from app layout (`cd beacon-app-layout && npm run build-storybook` or equivalent), then copy `storybook-static/*` into `apps/shell/public/design-system/` (or chosen path).
- [x] Add route `dev-tools` under platform-admin, component `PlatformAdminDevToolsPage`.
- [x] Dev tools page: iframe `src="/design-system/"` (or link “Open component catalog” to same path). No separate env var for URL; path is fixed relative to the deployed shell.

### 8.3 Verification

- [ ] Run `npm run storybook` in app layout locally; run beacon-tenant shell with built Storybook in public; open platform admin → Dev tools → catalog loads.

---

## 9. Implementation / review checklist (later — RCO components and blocks)

- [ ] Choose first RCO components to define (e.g. RCO-KPICard, one wrapper).
- [ ] Define token set and globals in app layout (if not already sufficient).
- [ ] Specify standard prop set (e.g. required `type`, optional title/variant) and document.
- [ ] Implement RCO-KPICard (and optionally one wrapper) in app layout; consume in one Beacon app as pilot.
- [ ] Document "layout wins" and "use RCO-* for cards/panels" in developer docs; add to review checklist.
- [ ] Design first block (e.g. RCO-Block-MiniDashboard): data contract, layout, composition of existing RCO-* components.
- [ ] Implement block in app layout; use in one app with real data.
- [ ] Revisit permissions/theming/analytics use of `type` when building those features.

---

*Plan captured from design discussion. Section 6 added for RCO-KPICard base + variants (Option A). Sections 7–8 for component registry (Storybook hosted by beacon-tenant).*
