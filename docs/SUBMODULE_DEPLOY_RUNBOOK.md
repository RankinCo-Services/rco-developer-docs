# Deploying when a submodule has changes

**Preferred:** Use the project's **deploy-all** script (e.g. `./scripts/deploy-all.sh "Feature: your message"`) so main repo and submodules are committed, pushed, and documented in one go. See [CROSS_REPO_DEVELOPMENT.md](CROSS_REPO_DEVELOPMENT.md).

This runbook is for **manual** steps when you only need to update one submodule or want to do it by hand.

## Pattern

When you change files inside a submodule:

1. **Commit and push inside the submodule**
2. **Update the main repo to point to that new commit, then deploy the main repo**

## Example (generic)

### Step 1: Commit and push in the submodule

```bash
cd <submodule>

git add -A
git status   # confirm changed files

git commit -m "Descriptive message"

git push origin main
```

### Step 2: Update main repo to use the new submodule commit and deploy

Back in the main repo, the submodule folder is now "ahead" of what the main repo's last commit recorded. Tell the main repo to use this new commit and push:

```bash
cd ..   # or: cd /path/to/main-repo

git add <submodule>
git status   # should show: modified <submodule> (new submodule commit)

./deploy "Update <submodule>: descriptive message"
```

Or without the deploy script:

```bash
git add <submodule>
git commit -m "Update <submodule>: descriptive message"
git push origin main
```

## Quick reference

| You changed…        | Do this first                    | Then in main repo                    |
|---------------------|----------------------------------|--------------------------------------|
| Submodule only      | `cd <submodule>` → commit, push  | `git add <submodule>` → `./deploy …` |
| Main repo only      | Nothing in submodules            | `./deploy "…"` as usual              |
| Both submodule + main | Commit & push in submodule first | Then `git add <submodule>` and `./deploy` |

## If `git push` in the submodule says "behind origin/main"

Pull (or rebase) first, then push:

```bash
cd <submodule>
git pull --rebase origin main
# fix any conflicts, then:
git push origin main
```

## See also

- [CROSS_REPO_DEVELOPMENT.md](CROSS_REPO_DEVELOPMENT.md) — Full cross-repo workflow and deploy-all.
- Project README or DEPLOYMENT.md for project-specific script names (e.g. deploy-all.sh).
