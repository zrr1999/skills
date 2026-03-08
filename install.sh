#!/usr/bin/env bash

set -euo pipefail

REPO_SOURCE="zrr1999/skills"
SKILLS_SOURCE="$REPO_SOURCE"

SCRIPT_PATH="${BASH_SOURCE[0]:-}"
if [[ -n "$SCRIPT_PATH" && "$SCRIPT_PATH" == */* ]]; then
  SCRIPT_DIR="$(cd -- "${SCRIPT_PATH%/*}" 2>/dev/null && pwd || true)"
  if [[ -n "$SCRIPT_DIR" && -d "$SCRIPT_DIR/skills" ]]; then
    SKILLS_SOURCE="$SCRIPT_DIR/skills"
  fi
fi

if ! command -v bun >/dev/null 2>&1; then
  echo "Error: bun is required but was not found in PATH." >&2
  echo "Install bun first: https://bun.sh/" >&2
  exit 1
fi

echo "Installing skills from $SKILLS_SOURCE"
bunx skills add "$SKILLS_SOURCE" -g --skill "*" -y
echo "Done."
