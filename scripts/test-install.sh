#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT
export INSTALL_TEST_BIN="$test_dir/bin"
export INSTALL_TEST_LOG="$test_dir/calls"
export INSTALL_TEST_STUB="$test_dir/stub"
export VP_HOME="$test_dir/vite"
mkdir -p "$INSTALL_TEST_BIN"

cat > "$INSTALL_TEST_STUB" <<'STUB'
#!/bin/bash
set -eu
name="${0##*/}"
printf '%s' "$name" >> "$INSTALL_TEST_LOG"
printf '\t%s' "$@" >> "$INSTALL_TEST_LOG"
printf '\n' >> "$INSTALL_TEST_LOG"
case "$name" in
  curl)
    cat <<'BOOTSTRAP'
cp "$INSTALL_TEST_STUB" "$INSTALL_TEST_BIN/vp"
cp "$INSTALL_TEST_STUB" "$INSTALL_TEST_BIN/vpx"
BOOTSTRAP
    ;;
  gh) printf 'ShigureLab/gh-llm\n' ;;
  vpx)
    if [[ "${INSTALL_TEST_FAIL:-}" == "1" ]]; then exit 7; fi
    ;;
esac
STUB
chmod +x "$INSTALL_TEST_STUB"
for name in vp vpx gh chub node curl; do
  cp "$INSTALL_TEST_STUB" "$INSTALL_TEST_BIN/$name"
done
export PATH="$INSTALL_TEST_BIN:/usr/bin:/bin"

run_install() {
  : > "$INSTALL_TEST_LOG"
  bash "$repo_dir/install.sh" "$@" > "$test_dir/output" 2>&1
}

assert_absent() {
  if grep -Eq -- "$1" "${2:-$INSTALL_TEST_LOG}"; then
    printf 'Unexpected match: %s\n' "$1" >&2
    exit 1
  fi
}

run_install
[[ "$(grep -c '^vpx' "$INSTALL_TEST_LOG")" == 7 ]]
assert_absent 'anthropics/skills|svg-assembly-animator|emil-design-eng|--all|animate-expo|agent.qq.com|vibe-motion'
assert_absent '^curl|^vp[[:space:]]'

REPO_SOURCE='fixture source with spaces' run_install web mail
grep -Fq "$(printf 'vpx\tskills\tadd\tfixture source with spaces\t-g')" "$INSTALL_TEST_LOG"
grep -Fq -- '--skill' "$INSTALL_TEST_LOG"
grep -Fq 'review-animations' "$INSTALL_TEST_LOG"
grep -Fq "$(printf 'vpx\tskills\tadd\thttps://agent.qq.com\t-g')" "$INSTALL_TEST_LOG"
assert_absent 'animate-expo'

run_install all
[[ "$(grep -c '^vpx' "$INSTALL_TEST_LOG")" == 12 ]]
grep -Fq 'animate-expo' "$INSTALL_TEST_LOG"
grep -Fq 'durable-objects' "$INSTALL_TEST_LOG"
grep -Fq 'ruler-progress-render' "$INSTALL_TEST_LOG"
assert_absent 'gh-stack|svg-assembly-animator|anthropics/skills|emil-design-eng|--all'

run_install --help
[[ ! -s "$INSTALL_TEST_LOG" ]]
if run_install unknown-profile; then
  printf 'Unknown profile unexpectedly succeeded\n' >&2
  exit 1
fi
[[ ! -s "$INSTALL_TEST_LOG" ]]

if INSTALL_TEST_FAIL=1 run_install all; then
  printf 'Failed install unexpectedly succeeded\n' >&2
  exit 1
fi
[[ "$(grep -c '^vpx' "$INSTALL_TEST_LOG")" == 1 ]]
assert_absent 'Done\.' "$test_dir/output"

rm "$INSTALL_TEST_BIN/vpx"
run_install
# Node already exists; missing vpx must still trigger Vite+ setup.
grep -q '^curl' "$INSTALL_TEST_LOG"
[[ "$(grep -c '^vpx' "$INSTALL_TEST_LOG")" == 7 ]]
printf 'Installer smoke checks passed (isolated tool stubs).\n'
