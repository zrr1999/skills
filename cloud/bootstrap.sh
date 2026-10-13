#!/usr/bin/env bash
# Downloaded by the platform hook; keep the reviewed runtime ref independent
# of the skill installer, which always follows its upstream default branch.
set -euo pipefail
pilot_mode="${1:-setup}"
case "$pilot_mode" in
  setup | maintenance) ;;
  *) printf 'Expected setup or maintenance.\n' >&2; exit 2 ;;
esac
shift || true
pilot_cache="${CLOUD_PILOT_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/cloud-pilot}"
pilot_source="$pilot_cache/runtime-source"
pilot_ref="${CLOUD_PILOT_RUNTIME_REF:-main}"
mkdir -p "$pilot_cache"
exec 8>"$pilot_cache/bootstrap.lock"
flock 8
if [[ ! -d "$pilot_source/.git" ]]; then
  git init "$pilot_source"
  git -C "$pilot_source" remote add origin https://github.com/zrr1999/skills.git
elif [[ -n "$(git -C "$pilot_source" status --porcelain)" ]]; then
  printf 'Runtime cache has local changes: %s\n' "$pilot_source" >&2
  exit 1
fi
git -C "$pilot_source" fetch --depth 1 origin "$pilot_ref"
git -C "$pilot_source" checkout --detach FETCH_HEAD
bash "$pilot_source/cloud/$pilot_mode.sh" "$@"
