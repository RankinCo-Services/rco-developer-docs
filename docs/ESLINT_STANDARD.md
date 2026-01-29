# ESLint standard for all projects

All RCO projects (including app repos and submodules like beacon-tenant, beacon-app-layout) must run ESLint on code changes. This document defines the standard, required setup, and how enforcement works.

## Policy

- **ESLint runs for every code change** in every project that contains lintable source (TypeScript/JavaScript).
- The agent (when using RCO Cursor config) is instructed to run ESLint in the appropriate directory before considering code complete or recommending commit.
- No project or package should be exempt without an explicit, documented exception.

## Required setup per project/package

Each repo or package that contains TypeScript/JavaScript source must have the following.

### 1. npm scripts in package.json

Add these scripts (names are standard so the agent and CI can rely on them):

| Script | Purpose |
|--------|---------|
| `lint` | Run ESLint (no fix). Must pass before code is considered complete. |
| `lint:fix` | Run ESLint with `--fix` to auto-fix fixable issues. |
| `lint:security` | Run ESLint with security rules (e.g. eslint-plugin-security). Optional but recommended. |
| `lint:security:fix` | Run security ESLint with `--fix`. Optional but recommended. |

**Example (Node/TypeScript):**

```json
{
  "scripts": {
    "lint": "eslint src --ext .ts",
    "lint:fix": "eslint src --ext .ts --fix",
    "lint:security": "eslint src --ext .ts --config .eslintrc.security.js",
    "lint:security:fix": "eslint src --ext .ts --config .eslintrc.security.js --fix"
  }
}
```

**Example (React/TypeScript frontend):**

```json
{
  "scripts": {
    "lint": "eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0",
    "lint:fix": "eslint . --ext ts,tsx --fix",
    "lint:security": "eslint . --ext ts,tsx --config .eslintrc.security.cjs",
    "lint:security:fix": "eslint . --ext ts,tsx --config .eslintrc.security.cjs --fix"
  }
}
```

### 2. ESLint config

- **Base config:** Use `.eslintrc.cjs`, `.eslintrc.js`, `eslint.config.js`, or `eslint.config.mjs` as appropriate for the project (and ensure any referenced plugins are in `devDependencies`).
- **Security config (optional but recommended):** A separate config that extends the base and adds security rules (e.g. `eslint-plugin-security`, `eslint-plugin-security-node`) so `lint:security` and `lint:security:fix` use it. Example: `.eslintrc.security.js` or `.eslintrc.security.cjs`.

### 3. Monorepos and submodules

- **Monorepos:** Each package that has source (e.g. `backend`, `frontend`, `packages/tenant-ui`) should have its own `package.json` with the four scripts above and its own ESLint config, or a root config that applies to all packages. The agent runs lint in each directory that contains modified files and has lint scripts.
- **Submodules (e.g. beacon-tenant):** Each submodule is a separate project. Add `lint`, `lint:fix`, `lint:security`, and `lint:security:fix` to each package that has source (e.g. `beacon-tenant/packages/tenant-ui/package.json`, `beacon-tenant/packages/tenant/` if it has TS source). Without these, the agent will report that setup is needed and will not skip lint for that package.

## Enforcement

### Via Cursor (RCO config)

When a project has copied the RCO Developer Documents Cursor config (via `scripts/copy-cursor-config.sh`), the rule **cursor/rules/eslint-after-changes.mdc** is merged into the project’s `.cursor/rules/`. That rule has `alwaysApply: true`, so the agent is instructed to:

1. Run `npm run lint:fix` (and, if present, `npm run lint:security:fix`) in the appropriate directory(s) after code changes.
2. Run `npm run lint` (and, if present, `npm run lint:security`) to verify before considering code complete or recommending commit.
3. Treat missing lint scripts as a blocker and direct the user to this document for setup.

So **enforcement for “all projects”** is achieved by:

1. **Adding lint scripts and config to every project** (see setup above).
2. **Copying RCO Cursor config** into each project so the ESLint rule is in effect. Any project that uses the copy script gets the rule; the agent then runs ESLint for that project when changes are made there.

### Via CI (optional)

To enforce ESLint in CI (e.g. block merge if lint fails), add a step to your workflow:

```yaml
# Example: GitHub Actions
- run: npm run lint
- run: npm run lint:security   # if present
```

Run these in each directory that has lint scripts (e.g. `backend`, `frontend`, or submodule packages). A shared workflow or template in rco-developer-docs can be added later if desired.

## Checklist for new projects or new packages

- [ ] Add `lint`, `lint:fix`, `lint:security`, `lint:security:fix` to package.json (or equivalent).
- [ ] Add base ESLint config and install required plugins/parsers (e.g. `@typescript-eslint/eslint-plugin`, `eslint-plugin-security`).
- [ ] Add security ESLint config if using `lint:security` (recommended).
- [ ] Run the RCO copy script from the project root so `.cursor/rules/` includes `eslint-after-changes.mdc`.
- [ ] Optionally add a CI step that runs `npm run lint` (and `npm run lint:security`) in each package.

## Reference

- **Rule file:** [cursor/rules/eslint-after-changes.mdc](../cursor/rules/eslint-after-changes.mdc)
- **Copy script:** [scripts/copy-cursor-config.sh](../scripts/copy-cursor-config.sh) — run from project root to merge RCO rules (including ESLint) into the project’s `.cursor/`.
