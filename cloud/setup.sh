#!/usr/bin/env bash
set -euo pipefail
pilot_scripts="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=cloud/env.sh
source "$pilot_scripts/env.sh"
mkdir -p "$CLOUD_PILOT_STATE_DIR"
exec 7>"$CLOUD_PILOT_STATE_DIR/setup.lock"
flock 7
bash "$pilot_scripts/install-base-tools.sh"
mkdir -p "$HOME/.config/cloud-pilot"
cp "$pilot_scripts/env.sh" "$HOME/.config/cloud-pilot/env.sh"
for pilot_shell_file in "$HOME/.bashrc" "$HOME/.profile"; do
  # Keep HOME literal so it is expanded by the next shell, not by setup.
  # shellcheck disable=SC2016
  pilot_source_line='[ ! -f "$HOME/.config/cloud-pilot/env.sh" ] || . "$HOME/.config/cloud-pilot/env.sh"'
  touch "$pilot_shell_file"
  if ! grep -Fxq "$pilot_source_line" "$pilot_shell_file"; then
    printf '\n%s\n' "$pilot_source_line" >>"$pilot_shell_file"
  fi
done
python3 "$pilot_scripts/repositories.py" "$pilot_scripts/profile.json"
bash "$pilot_scripts/sync-skills.sh" "$@"
printf 'Shared environment setup completed.\n'
