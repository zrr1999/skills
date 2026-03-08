#!/usr/bin/env bash

set -euo pipefail

REPO_SOURCE="zrr1999/skills"

if ! command -v bun >/dev/null 2>&1; then
  echo "bun not found, installing via official script..."
  export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
  curl -fsSL https://bun.sh/install | bash
  export PATH="$BUN_INSTALL/bin:$PATH"
fi

echo "Installing skills from $REPO_SOURCE"
bunx skills add "$REPO_SOURCE" --all -g
echo "Done."
