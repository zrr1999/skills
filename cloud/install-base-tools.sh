#!/usr/bin/env bash
# Shared Python and Web development tools. Project dependencies remain in each
# repository's own environment; run project tests with uv run pytest.
set -euo pipefail
pilot_scripts="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=cloud/env.sh
source "$pilot_scripts/env.sh"
mkdir -p "$HOME/.local/bin"

for pilot_prerequisite in curl git python3 flock; do
  if ! command -v "$pilot_prerequisite" >/dev/null 2>&1; then
    printf 'Required base-image tool is missing: %s\n' "$pilot_prerequisite" >&2
    exit 1
  fi
done

if ! command -v uv >/dev/null 2>&1; then
  pilot_uv_installer="$(mktemp)"
  curl -fsSL https://astral.sh/uv/install.sh -o "$pilot_uv_installer"
  bash "$pilot_uv_installer"
  rm -f "$pilot_uv_installer"
fi

if ! command -v vp >/dev/null 2>&1 || ! command -v vpx >/dev/null 2>&1; then
  pilot_installer="$(mktemp)"
  curl -fsSL https://vite.plus -o "$pilot_installer"
  bash "$pilot_installer"
  rm -f "$pilot_installer"
fi
# Cache the pilot repositories' runtimes and package managers without changing
# global defaults or adding version pins to any repository.
for pilot_environment in 22 24 pnpm@10.33.0 pnpm@11.28.0; do
  vp env install "$pilot_environment"
done
# Expose pnpm through Vite+'s shim so direct pnpm commands also resolve the
# packageManager version declared by the current repository.
vp env on pnpm
for pilot_python in 3.12 3.13 3.14; do
  if ! uv python find --no-python-downloads "$pilot_python" >/dev/null 2>&1; then
    uv python install "$pilot_python"
  fi
done

install_python_tool() {
  local executable="$1"
  shift
  if command -v "$executable" >/dev/null 2>&1; then
    return
  fi
  uv tool install "$@"
}
install_python_tool ty ty
install_python_tool ruff ruff
install_python_tool pyrefly pyrefly
install_python_tool pytest --with pytest-cov pytest
install_python_tool just rust-just
install_python_tool prek prek
install_python_tool gh-llm --python 3.14 gh-llm
install_python_tool zendev --python 3.12 zendev

for pilot_tool in gh fd zellij shellcheck lychee; do
  if ! command -v "$pilot_tool" >/dev/null 2>&1; then
    python3 "$pilot_scripts/install-release-tool.py" "$pilot_tool"
  fi
done

install_python_tool playwright playwright
pilot_browser_check="$(mktemp -d)"
trap 'rm -rf "$pilot_browser_check"' EXIT
pilot_page='data:text/html,<title>Cloud pilot</title><p>Browser check</p>'
if ! playwright screenshot --browser chromium --timeout 20000 "$pilot_page" "$pilot_browser_check/check.png" >"$pilot_browser_check/check.log" 2>&1; then
  if [[ "$(id -u)" == "0" ]]; then
    playwright install --with-deps chromium
  else
    playwright install chromium
  fi
  if ! playwright screenshot --browser chromium --timeout 20000 "$pilot_page" "$pilot_browser_check/check.png" >"$pilot_browser_check/check.log" 2>&1; then
    cat "$pilot_browser_check/check.log" >&2
    exit 1
  fi
fi
printf 'Chromium screenshot check passed.\n'

mkdir -p "$CLOUD_PILOT_STATE_DIR"
python3 - "$CLOUD_PILOT_STATE_DIR/base-tools-state.json" <<'PY'
import json
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

commands = {
    "gh": ["gh", "--version"], "lychee": ["lychee", "--version"],
    "uv": ["uv", "--version"], "ty": ["ty", "--version"],
    "ruff": ["ruff", "--version"], "pyrefly": ["pyrefly", "--version"],
    "pytest": ["pytest", "--version"], "just": ["just", "--version"],
    "prek": ["prek", "--version"], "gh-llm": ["gh-llm", "--version"],
    "zendev": ["zendev", "--help"], "vp": ["vp", "--version"],
    "vpx": ["vpx", "--version"], "node": ["node", "--version"],
    "pnpm": ["pnpm", "--version"],
    "fd": ["fd", "--version"], "zellij": ["zellij", "--version"],
    "shellcheck": ["shellcheck", "--version"], "playwright": ["playwright", "--version"],
}
tools = {}
for name, command in commands.items():
    result = subprocess.run(command, capture_output=True, text=True, timeout=20)
    if result.returncode:
        raise SystemExit(f"Tool validation failed: {name}: {result.stderr}")
    lines = result.stdout.strip().splitlines()
    tools[name] = {"path": shutil.which(name), "version_output": "\n".join(lines[:3])}
state = {"verified_at": datetime.now(timezone.utc).isoformat(), "chromium_screenshot": "passed", "tools": tools}
Path(sys.argv[1]).write_text(json.dumps(state, ensure_ascii=False, indent=2) + "\n")
print(f"Verified {len(tools)} tools; state: {sys.argv[1]}")
PY
