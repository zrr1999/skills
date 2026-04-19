#!/usr/bin/env bash

set -euo pipefail

REPO_SOURCE="${REPO_SOURCE:-zrr1999/skills}"
GH_EXTENSIONS=(
  "ShigureLab/gh-llm:gh-llm"
)

has() {
  command -v "$1" >/dev/null 2>&1
}

log() {
  printf '==> %s\n' "$*"
}

ensure_bun() {
  if has bun; then
    return
  fi

  log "bun not found, installing via brew or x-cmd..."
  if has brew; then
    brew install bun
  elif has x; then
    x env use bun
  else
    echo "error: neither brew nor x-cmd found; install bun manually: https://bun.sh" >&2
    exit 1
  fi
}

ensure_gh_extensions() {
  if ! has gh; then
    log "gh not found, skipping gh extensions."
    return
  fi

  local entry repo extension
  for entry in "${GH_EXTENSIONS[@]}"; do
    IFS=":" read -r repo extension <<<"$entry"
    if gh extension list | grep -Fq "$repo"; then
      log "Upgrading gh extension $extension..."
      gh extension upgrade "$extension"
    else
      log "Installing gh extension $repo..."
      gh extension install "$repo"
    fi
  done
}

install_chub() {
  if has chub; then
    return
  fi
  log "Installing chub (required by get-api-docs skill)..."
  bun install -g @aisuite/chub
}

install_skills() {
  log "Installing skills from $REPO_SOURCE..."
  bunx skills add "$REPO_SOURCE" --all -g

  log "Installing external skills..."
  bunx skills add anthropics/skills        -g --skill skill-creator
  bunx skills add cloudflare/skills        -g --skill cloudflare --skill wrangler
  bunx skills add shigurelab/gh-llm        -g --skill github-conversation
  bunx skills add aviator-co/agent-plugins -g --skill av-cli
  bunx skills add vibe-motion/skills       -g --skill svg-assembly-animator --skill procedural-fish-render --skill ruler-progress-render
  bunx skills add spore-lang/spore         -g --skill spore-language
}

main() {
  ensure_bun
  ensure_gh_extensions
  install_chub
  install_skills

  log "Done."
}

main "$@"
