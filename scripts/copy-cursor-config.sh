#!/usr/bin/env bash
# Copy RCO Developer Documents Cursor config into the current project's .cursor/
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
mkdir -p "$CURSOR_DIR"

for dir in agents rules references skills; do
  if [ -d "$RCO_DOCS_ROOT/cursor/$dir" ]; then
    cp -R "$RCO_DOCS_ROOT/cursor/$dir" "$CURSOR_DIR/"
    echo "Copied cursor/$dir -> $CURSOR_DIR/"
  fi
done

echo "Done. Cursor config copied into $CURSOR_DIR"
