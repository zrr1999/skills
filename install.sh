#!/usr/bin/env bash

set -euo pipefail

REPO_SOURCE="${REPO_SOURCE:-zrr1999/skills}"
SKILLS_AGENT="${SKILLS_AGENT:-cline}"
GH_EXTENSIONS=(
  "ShigureLab/gh-llm:gh-llm"
)

has() {
  command -v "$1" >/dev/null 2>&1
}

log() {
  printf '==> %s\n' "$*"
}

ensure_vite() {
  if has vp && has vpx; then
    return
  fi

  log "Installing Vite+ (vp): curl -fsSL https://vite.plus | bash"
  export VP_NODE_MANAGER="${VP_NODE_MANAGER:-yes}"
  curl -fsSL https://vite.plus | bash

  export VP_HOME="${VP_HOME:-$HOME/.vite-plus}"
  export PATH="$VP_HOME/bin:$HOME/.local/bin:$PATH"

  if ! has vp || ! has vpx; then
    log "error: vp/vpx not found after install. Add $VP_HOME/bin to PATH and retry."
    return 1
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
      log "gh extension $extension is already installed."
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
  vp add -g @aisuite/chub

  if ! has chub; then
    log "error: chub not found after install. Check Vite+ global binaries and retry."
    return 1
  fi
}

# Pin installs to ~/.agents/skills only. `cline` (also warp/zed/dexto) uses that
# globalSkillsDir. Do NOT use `--all`: it expands to `--agent '*'`, which fans
# out symlinks into dozens of agent dirs.
add_skills() {
  local source="$1" skill
  shift
  local args=()
  for skill in "$@"; do
    args+=(--skill "$skill")
  done
  vpx skills add "$source" -g -y --agent "$SKILLS_AGENT" "${args[@]}"
}

install_core() {
  add_skills "$REPO_SOURCE" '*'
  add_skills vercel-labs/skills find-skills
  add_skills emilkowalski/skills write-swift
  add_skills pbakaus/impeccable impeccable
  add_skills cloudflare/skills cloudflare wrangler
  add_skills shigurelab/gh-llm github-conversation
  add_skills spore-lang/spore spore-language
}

install_profile() {
  case "$1" in
    web)
      add_skills emilkowalski/skills animate apple-design review-animations prototype \
        pick-ui-library ask-sonner animation-vocabulary find-animation-opportunities improve-animations
      ;;
    expo) add_skills emilkowalski/skills animate-expo ;;
    cloudflare) add_skills cloudflare/skills workers-best-practices durable-objects ;;
    mail) add_skills https://agent.qq.com/.well-known/skills/agently-mail/SKILL.md agently-mail ;;
    video) add_skills vibe-motion/skills procedural-fish-render ruler-progress-render ;;
  esac
}

usage() {
  cat <<'EOF'
Usage: bash install.sh [web] [expo] [cloudflare] [mail] [video] | all

Installs the core skills and any selected optional profiles.
REPO_SOURCE overrides the repository source; SKILLS_AGENT defaults to cline.
For routine updates, run: vpx skills update -g
EOF
}

main() {
  local profile
  for profile in "$@"; do
    case "$profile" in
      -h | --help) usage; return ;;
      web | expo | cloudflare | mail | video | all) ;;
      *) usage >&2; return 2 ;;
    esac
  done
  if [[ " $* " == *" all "* ]]; then
    set -- web expo cloudflare mail video
  fi

  ensure_vite
  ensure_gh_extensions
  install_chub
  install_core
  for profile in "$@"; do
    install_profile "$profile"
  done

  log "Done. Update installed skills with: vpx skills update -g"
}

main "$@"
