#!/usr/bin/env bash
# Run from the environment setup and maintenance hooks, before starting an agent.
# Default: the complete collection selected by zrr1999/skills/install.sh all.
set -euo pipefail

pilot_scripts="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=cloud/env.sh
source "$pilot_scripts/env.sh"

pilot_state="$CLOUD_PILOT_STATE_DIR"
pilot_cache="$CLOUD_PILOT_CACHE_DIR"
pilot_source="$pilot_cache/skills-source"
pilot_profiles=("$@")
if [[ ${#pilot_profiles[@]} -eq 0 ]]; then
  pilot_profiles=(all)
fi
for pilot_profile in "${pilot_profiles[@]}"; do
  case "$pilot_profile" in
    all|web|expo|cloudflare|mail|video) ;;
    *) printf 'Unknown profile: %s\n' "$pilot_profile" >&2; exit 2 ;;
  esac
done

mkdir -p "$pilot_state" "$pilot_cache"
exec 9>"$pilot_state/refresh.lock"
flock 9
pilot_run="$(mktemp -d "$pilot_state/refresh-XXXXXXXX")"
printf 'Skill refresh log: %s\n' "$pilot_run/refresh.log"

# A failed refresh restores both files and registered source metadata.
python3 "$pilot_scripts/skills-state.py" snapshot "$HOME/.agents" "$pilot_run"

refresh_skills() {
  if [[ ! -d "$pilot_source/.git" ]]; then
    git clone --depth 1 https://github.com/zrr1999/skills.git "$pilot_source"
  else
    if [[ -n "$(git -C "$pilot_source" status --porcelain)" ]]; then
      printf 'The managed installer cache contains local edits: %s\n' "$pilot_source" >&2
      return 1
    fi
    git -C "$pilot_source" fetch --depth 1 origin HEAD
    git -C "$pilot_source" checkout --detach FETCH_HEAD
  fi

  pilot_revision="$(git -C "$pilot_source" rev-parse HEAD)"
  if python3 - "$pilot_state/skills-state.json" "$pilot_revision" "$HOME/.agents/skills" "${pilot_profiles[@]}" <<'PY'
import json
import sys
from pathlib import Path

try:
    previous = json.loads(Path(sys.argv[1]).read_text())
    root = Path(sys.argv[3])
    unchanged = previous['installer_revision'] == sys.argv[2] and previous['profiles'] == sys.argv[4:]
    present = all((root / skill['name'] / 'SKILL.md').is_file() for skill in previous['skills'])
    ready = unchanged and present
except (OSError, ValueError, KeyError, TypeError):
    ready = False
sys.exit(0 if ready else 1)
PY
  then
    printf 'Installer revision and skill collection unchanged; checking registered source updates.\n'
  else
    # Reconcile on first setup or a changed upstream collection; update alone
    # does not add new skill entries from install.sh or newly added core skills.
    bash "$pilot_source/install.sh" "${pilot_profiles[@]}"
  fi
  vpx skills update -g -y
  vpx skills list -g --json >"$pilot_run/installed-skills.json"
  git -C "$pilot_source" rev-parse HEAD >"$pilot_run/installer-revision.txt"
}

set +e
(set -e; refresh_skills) >"$pilot_run/refresh.log" 2>&1
pilot_result=$?
set -e
if [[ "$pilot_result" -ne 0 ]]; then
  python3 "$pilot_scripts/skills-state.py" restore "$HOME/.agents" "$pilot_run"
  tail -n 60 "$pilot_run/refresh.log" >&2
  printf 'Skill refresh failed; latest state was not marked successful. Exit: %s\n' "$pilot_result" >&2
  exit "$pilot_result"
fi

python3 - "$pilot_run" "$pilot_state" "$HOME/.agents/skills" "${pilot_profiles[@]}" <<'PY'
import hashlib
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

run, state, root = map(Path, sys.argv[1:4])
skills = []
for directory in sorted(root.iterdir()):
    if not (directory / "SKILL.md").is_file():
        continue
    files = {}
    for path in sorted(directory.rglob("*")):
        if path.is_file():
            files[str(path.relative_to(directory))] = hashlib.sha256(path.read_bytes()).hexdigest()
    skills.append({"name": directory.name, "files_sha256": files})
result = {
    "schema_version": 1,
    "refreshed_at": datetime.now(timezone.utc).isoformat(),
    "installer_source": "zrr1999/skills",
    "installer_revision": (run / "installer-revision.txt").read_text().strip(),
    "profiles": sys.argv[4:],
    "skills": skills,
    "registered_installs": json.loads((run / "installed-skills.json").read_text()),
    "refresh_log": str(run / "refresh.log"),
}
text = json.dumps(result, indent=2, ensure_ascii=False) + "\n"
(run / "skills-state.json").write_text(text)
temporary = state / "skills-state.json.tmp"
temporary.write_text(text)
temporary.replace(state / "skills-state.json")
print(f"Skills ready: {len(skills)}; state: {state / 'skills-state.json'}")
PY
