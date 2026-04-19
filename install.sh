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

ensure_node() {
  if has node; then
    return
  fi

  log "Installing fnm..."
  curl -fsSL https://fnm.vercel.app/install | bash
  export PATH="$HOME/.local/share/fnm:$PATH"
  eval "$(fnm env)"

  log "Installing Node.js LTS via fnm..."
  fnm install --lts
  fnm use lts-latest
}

ensure_pnpm() {
  if has pnpm; then
    return
  fi

  log "Installing pnpm..."
  curl -fsSL https://get.pnpm.io/install.sh | sh -
  export PATH="$HOME/.local/share/pnpm:$PATH"
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
  pnpm install -g @aisuite/chub
}

install_skills() {
  log "Installing skills from $REPO_SOURCE..."
  pnpx skills add "$REPO_SOURCE" --all -g

  log "Installing external skills..."
  pnpx skills add anthropics/skills        -g --skill skill-creator
  pnpx skills add cloudflare/skills        -g --skill cloudflare --skill wrangler
  pnpx skills add shigurelab/gh-llm        -g --skill github-conversation
  pnpx skills add aviator-co/agent-plugins -g --skill av-cli
  pnpx skills add vibe-motion/skills       -g --skill svg-assembly-animator --skill procedural-fish-render --skill ruler-progress-render
  pnpx skills add spore-lang/spore         -g --skill spore-language
}

main() {
  ensure_node
  ensure_pnpm
  ensure_gh_extensions
  install_chub
  install_skills

  log "Done."
}

main "$@"
