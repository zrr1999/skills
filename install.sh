#!/usr/bin/env bash

set -euo pipefail

REPO_SOURCE="${REPO_SOURCE:-zrr1999/skills}"

SYSTEM_PACKAGES=(curl ca-certificates git jq fzf duf git-lfs)
CARGO_TOOLS=(
  "bat:bat"
  "fd-find:fd"
  "ripgrep:rg"
  "sd:sd"
  "ast-grep:sg"
  "lsd:lsd"
  "bottom:btm"
  "du-dust:dust"
  "procs:procs"
  "git-delta:delta"
  "difftastic:difft"
  "hyperfine:hyperfine"
)
UV_TOOLS=(
  "httpie:http"
)

APT_UPDATED=0
SUDO=()

prepend_path() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) export PATH="$1:$PATH" ;;
  esac
}

persist_path_dir() {
  local dir=$1
  local line="export PATH=\"$dir:\$PATH\""
  local file
  local files=("$HOME/.profile")

  [[ -f "$HOME/.bashrc" ]] && files+=("$HOME/.bashrc")
  [[ -f "$HOME/.zshrc" ]] && files+=("$HOME/.zshrc")

  prepend_path "$dir"

  for file in "${files[@]}"; do
    touch "$file"
    if ! grep -Fqx "$line" "$file" 2>/dev/null; then
      printf '\n%s\n' "$line" >>"$file"
    fi
  done
}

version_gte() {
  local current=$1
  local minimum=$2

  [[ "$(printf '%s\n%s\n' "$minimum" "$current" | sort -V | tail -n1)" == "$current" ]]
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

ensure_bun() {
  persist_path_dir "${BUN_INSTALL:-$HOME/.bun}/bin"

  if has bun; then
    log "bun already installed."
    return
  fi

  log "Installing bun via official script..."
  export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
  curl -fsSL https://bun.sh/install | bash
  persist_path_dir "$BUN_INSTALL/bin"
}

ensure_uv() {
  persist_path_dir "$HOME/.local/bin"

  if has uv; then
    log "uv already installed."
    return
  fi

  log "Installing uv via official script..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  persist_path_dir "$HOME/.local/bin"
}

ensure_rust_toolchain() {
  local cargo_version=""

  persist_path_dir "$HOME/.cargo/bin"

  if has cargo; then
    cargo_version=$(cargo -V | awk '{print $2}')
    if version_gte "$cargo_version" "1.85.0"; then
      log "cargo $cargo_version already installed."
      return
    fi

    log "cargo $cargo_version is older than 1.85.0; upgrading via rustup..."
  fi

  apt_install build-essential
  apt_install pkg-config
  apt_install libssl-dev

  if ! has rustup; then
    log "Installing rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
  fi

  log "Installing or updating stable Rust toolchain..."
  rustup toolchain install stable --profile minimal
  rustup default stable
  persist_path_dir "$HOME/.cargo/bin"
}

ensure_cargo_binstall() {
  if cargo binstall --help >/dev/null 2>&1; then
    log "cargo-binstall already installed."
    return
  fi

  log "Installing cargo-binstall via official script..."
  curl -L --proto '=https' --tlsv1.2 -sSf \
    https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
}

install_cargo_tool() {
  local crate=$1
  local binary=$2

  if has "$binary"; then
    log "$binary already installed."
    return
  fi

  log "Installing $crate..."
  if ! cargo binstall --locked --no-confirm "$crate"; then
    log "cargo-binstall failed for $crate, falling back to cargo install."
    cargo install --locked "$crate"
  fi
}

install_uv_tool() {
  local package=$1
  local binary=$2

  if has "$binary"; then
    log "$binary already installed."
    return
  fi

  log "Installing $package via uv tool..."
  uv tool install "$package"
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

install_cli_tools() {
  local entry crate binary

  ensure_rust_toolchain
  ensure_cargo_binstall

  for entry in "${CARGO_TOOLS[@]}"; do
    IFS=":" read -r crate binary <<<"$entry"
    install_cargo_tool "$crate" "$binary"
  done

  for entry in "${UV_TOOLS[@]}"; do
    IFS=":" read -r crate binary <<<"$entry"
    install_uv_tool "$crate" "$binary"
  done
}

configure_tools() {
  if has git-lfs; then
    log "Configuring git-lfs..."
    git lfs install --skip-repo
  fi
}

main() {
  install_system_packages
  ensure_bun
  ensure_uv
  install_cli_tools
  configure_tools

  log "Installing skills from $REPO_SOURCE..."
  bunx skills add "$REPO_SOURCE" --all -g
  log "Done."
}

main "$@"
