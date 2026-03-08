#!/usr/bin/env bash

set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]}"
if [[ "$SCRIPT_PATH" == */* ]]; then
  SCRIPT_DIR="$(cd -- "${SCRIPT_PATH%/*}" && pwd)"
else
  SCRIPT_DIR="$(pwd)"
fi
SKILLS_DIR="$SCRIPT_DIR/skills"

if ! command -v bun >/dev/null 2>&1; then
  echo "Error: bun is required but was not found in PATH." >&2
  echo "Install bun first: https://bun.sh/" >&2
  exit 1
fi

if [ ! -d "$SKILLS_DIR" ]; then
  echo "Error: skills directory not found: $SKILLS_DIR" >&2
  exit 1
fi

echo "Installing skills from $SKILLS_DIR"
bunx skills add "$SKILLS_DIR" -g --skill "*" -y
echo "Done."
