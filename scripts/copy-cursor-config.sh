#!/usr/bin/env bash
# Merge RCO Developer Documents Cursor config into the current project's .cursor/
# Adds RCO rules, agents, references, and skills WITHOUT removing existing project files.
# Run from your project root: /path/to/rco-developer-docs/scripts/copy-cursor-config.sh
# Or from project root: ../rco-developer-docs/scripts/copy-cursor-config.sh

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

for dir in agents rules references skills; do
  if [ -d "$RCO_DOCS_ROOT/cursor/$dir" ]; then
    mkdir -p "$CURSOR_DIR/$dir"
    # Merge: copy RCO contents into project dir (existing project files are kept)
    cp -R "$RCO_DOCS_ROOT/cursor/$dir"/* "$CURSOR_DIR/$dir/" 2>/dev/null || true
    echo "Merged cursor/$dir -> $CURSOR_DIR/$dir (existing files kept)"
  fi
done

echo "Done. RCO Cursor config merged into $CURSOR_DIR (project rules/agents/references/skills preserved)"
