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

  log "Installing Vite+ (vp): curl -fsSL https://vite.plus | bash"
  export VP_NODE_MANAGER="${VP_NODE_MANAGER:-yes}"
  curl -fsSL https://vite.plus | bash

  export VP_HOME="${VP_HOME:-$HOME/.vite-plus}"
  export PATH="$VP_HOME/bin:$HOME/.local/bin:$PATH"

  if ! has vp; then
    log "error: vp not found after Vite+ install. Add $VP_HOME/bin (and ~/.local/bin if needed) to PATH."
    return 1
  fi

  log "Configuring Vite+ managed Node.js (LTS)..."
  vp env setup --refresh 2>/dev/null || vp env setup
  vp env on 2>/dev/null || true
  vp env default lts 2>/dev/null || true
  if vp env print >/dev/null 2>&1; then
    eval "$(vp env print)"
  fi

  if ! has node; then
    vp env install lts 2>/dev/null || true
    if vp env print >/dev/null 2>&1; then
      eval "$(vp env print)"
    fi
  fi

  if ! has node; then
    log "error: node not available after Vite+ setup. Try a new shell, or run: eval \"\$(vp env print)\""
    return 1
  fi
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
  pnpx skills add "$REPO_SOURCE" --all -g -y
  pnpx skills add "$REPO_SOURCE" -g --skill project-workflows \
    --skill tech-preferences \
    --skill unix-software-design \
    --skill modern-python \
    --skill get-api-docs \
    --skill compound-learnings \
    --skill spark \
    --skill release-quality \
    --skill tech-debt-audit

  pnpx skills add anthropics/skills -g --skill skill-creator -y
  pnpx skills add cloudflare/skills -g --skill cloudflare --skill wrangler -y
  pnpx skills add shigurelab/gh-llm -g --skill github-conversation -y
  pnpx skills add aviator-co/agent-plugins -g --skill av-cli -y
  pnpx skills add vibe-motion/skills -g --skill svg-assembly-animator --skill procedural-fish-render --skill ruler-progress-render -y
  pnpx skills add spore-lang/spore -g --skill spore-language -y
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
