#!/usr/bin/env bash
# Merge RCO Developer Documents into the current project:
# - .cursor/ (agents, rules, references, skills) — RCO rules merged; existing project files kept.
# - docs/rco-standards/ — All docs from docs/ (both .md and .mdc): deploy workflow, Render runbook, architecture,
#   authoritative topic docs (e.g. RBAC_AND_PERMISSIONS.md + .mdc), ESLint standard.
# - .cursor/references/ — Copies of docs/*.mdc so full authoritative .mdc docs appear in Cursor references for easy viewing.
# Run from your project root: /path/to/rco-developer-docs/scripts/copy-cursor-config.sh [target_dir]
# Or from project root: ../rco-developer-docs/scripts/copy-cursor-config.sh
# Target defaults to current directory (.) if not provided.

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RCO_DOCS_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET="${1:-.}"

if [ ! -d "$RCO_DOCS_ROOT/cursor" ]; then
  echo "Error: cursor/ not found in $RCO_DOCS_ROOT"
  exit 1
fi

TARGET_ROOT="$(cd "$TARGET" 2>/dev/null && pwd)" || { echo "Error: target $TARGET not found or not a directory"; exit 1; }
CURSOR_DIR="$TARGET_ROOT/.cursor"

# Merge .cursor/ (agents, rules, references, skills)
for dir in agents rules references skills; do
  if [ -d "$RCO_DOCS_ROOT/cursor/$dir" ]; then
    mkdir -p "$CURSOR_DIR/$dir"
    cp -R "$RCO_DOCS_ROOT/cursor/$dir"/* "$CURSOR_DIR/$dir/" 2>/dev/null || true
    echo "Merged cursor/$dir -> $CURSOR_DIR/$dir (existing files kept)"
  fi
done

# Copy docs/ into project docs/rco-standards/ (all .md and .mdc: deploy workflow, Render runbook, architecture, authoritative topic docs)
if [ -d "$RCO_DOCS_ROOT/docs" ]; then
  RCO_STANDARDS_DIR="$TARGET_ROOT/docs/rco-standards"
  mkdir -p "$RCO_STANDARDS_DIR"
  for f in "$RCO_DOCS_ROOT/docs"/*; do
    if [ -f "$f" ]; then
      cp "$f" "$RCO_STANDARDS_DIR/"
      echo "Copied docs/$(basename "$f") -> docs/rco-standards/"
    fi
  done
fi

# Copy docs/*.mdc into project .cursor/references/ for easy developer viewing in Cursor
if [ -d "$RCO_DOCS_ROOT/docs" ]; then
  mkdir -p "$CURSOR_DIR/references"
  for f in "$RCO_DOCS_ROOT/docs"/*.mdc; do
    if [ -f "$f" ]; then
      cp "$f" "$CURSOR_DIR/references/"
      echo "Copied docs/$(basename "$f") -> .cursor/references/"
    fi
  done
fi

echo "Done. RCO Cursor config and docs merged into $TARGET_ROOT (rules/agents/references/skills preserved; docs in docs/rco-standards/; .mdc also in .cursor/references/)"
