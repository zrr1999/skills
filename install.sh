#!/usr/bin/env bash

set -euo pipefail

REPO_SOURCE="${REPO_SOURCE:-zrr1999/skills}"
SYSTEM_PACKAGES=(curl ca-certificates git git-lfs)
XCMD_PACKAGES=(bun uv gh jq fzf duf bat rg fd sd lsd bottom dust procs delta difft hyperfine httpie)
BUN_GLOBAL_PACKAGES=("@aisuite/chub")
GH_EXTENSIONS=(
  "ShigureLab/gh-llm:gh-llm"
)

APT_UPDATED=0
SUDO=()

persist_path_dir() {
  local dir=$1
  local line="export PATH=\"$dir:\$PATH\""
  local file
  local files=("$HOME/.profile")

  [[ -f "$HOME/.bashrc" ]] && files+=("$HOME/.bashrc")
  [[ -f "$HOME/.zshrc" ]] && files+=("$HOME/.zshrc")

  case ":$PATH:" in
    *":$dir:"*) ;;
    *) export PATH="$dir:$PATH" ;;
  esac

  for file in "${files[@]}"; do
    touch "$file"
    if ! grep -Fqx "$line" "$file" 2>/dev/null; then
      printf '\n%s\n' "$line" >>"$file"
    fi
  done
}

has() {
  command -v "$1" >/dev/null 2>&1
}

log() {
  printf '==> %s\n' "$*"
}

setup_sudo() {
  if has sudo; then
    SUDO=(sudo)
  elif [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    SUDO=()
  else
    echo "error: sudo is required to install system packages" >&2
    exit 1
  fi
}

apt_update_once() {
  if ! has apt-get; then
    return
  fi

  if [[ "$APT_UPDATED" -eq 0 ]]; then
    log "Refreshing apt package index..."
    "${SUDO[@]}" apt-get update
    APT_UPDATED=1
  fi
}

apt_install() {
  local package=$1

  if ! has apt-get; then
    log "Skipping $package because apt-get is unavailable."
    return
  fi

  if dpkg -s "$package" >/dev/null 2>&1; then
    log "$package already installed."
    return
  fi

  apt_update_once

  if ! apt-cache show "$package" >/dev/null 2>&1; then
    log "Skipping $package because it is unavailable in apt."
    return
  fi

  log "Installing $package via apt-get..."
  "${SUDO[@]}" apt-get install -y --no-install-recommends "$package"
}

with_nounset_disabled() {
  local restore_nounset=0
  if [[ $- == *u* ]]; then
    restore_nounset=1
    set +u
  fi

  "$@"

  if [[ "$restore_nounset" -eq 1 ]]; then
    set -u
  fi
}

install_xcmd_script() {
  eval "$(curl -fsSL https://get.x-cmd.com)"
}

source_xcmd() {
  # shellcheck disable=SC1090
  . "$HOME/.x-cmd.root/X"
}

ensure_xcmd() {
  persist_path_dir "$HOME/.local/bin"

  if [[ ! -f "$HOME/.x-cmd.root/X" ]]; then
    log "Installing x-cmd..."
    with_nounset_disabled install_xcmd_script
  fi

  if ! has x; then
    with_nounset_disabled source_xcmd
  fi

  if ! has x; then
    echo "error: x-cmd installation failed" >&2
    exit 1
  fi
}

install_xcmd_packages() {
  ensure_xcmd
  log "Installing CLI tools with x-cmd..."
  with_nounset_disabled x env use "${XCMD_PACKAGES[@]}"
}

ensure_gh_extensions() {
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
    log "chub already installed."
    return
  fi
  log "Installing chub (Context Hub CLI)..."
  bun install -g @aisuite/chub
}

install_system_packages() {
  if ! has apt-get; then
    log "apt-get not found; skipping apt-managed tools."
    return
  fi

  setup_sudo
  for package in "${SYSTEM_PACKAGES[@]}"; do
    apt_install "$package"
  done
}

configure_tools() {
  if has git-lfs; then
    log "Configuring git-lfs..."
    git lfs install --skip-repo
  fi
}

install_skills() {
  log "Installing skills from $REPO_SOURCE..."
  bunx skills add "$REPO_SOURCE" --all -g

  log "Installing external skills..."
  bunx skills add anthropics/skills       -g --skill skill-creator
  bunx skills add cloudflare/skills       -g --skill cloudflare --skill wrangler
  bunx skills add shigurelab/gh-llm       -g --skill github-conversation
  bunx skills add aviator-co/agent-plugins -g --skill av-cli
  bunx skills add vibe-motion/skills      -g --skill svg-assembly-animator --skill procedural-fish-render --skill ruler-progress-render
  bunx skills add spore-lang/spore        -g --skill spore-language
}

main() {
  install_system_packages
  install_xcmd_packages
  ensure_gh_extensions
  configure_tools

  install_chub
  install_skills

  log "Done."
}

main "$@"
