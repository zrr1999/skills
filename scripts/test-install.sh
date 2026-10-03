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

cat >"$INSTALL_TEST_STUB" <<'STUB'
#!/bin/bash
set -eu
printf '%s' "${0##*/}" >>"$INSTALL_TEST_LOG"
printf '\t%s' "$@" >>"$INSTALL_TEST_LOG"
printf '\n' >>"$INSTALL_TEST_LOG"
case "${0##*/}" in
  curl)
    printf '%s\n' 'mkdir -p "$VP_HOME/bin" && cp "$INSTALL_TEST_STUB" "$VP_HOME/bin/vp" && cp "$INSTALL_TEST_STUB" "$VP_HOME/bin/vpx"'
    ;;
  gh) printf 'ShigureLab/gh-llm\n' ;;
  vpx) [[ "${INSTALL_TEST_FAIL:-}" != 1 ]] ;;
esac
STUB
chmod +x "$INSTALL_TEST_STUB"
for name in vp vpx gh chub node curl; do
  cp "$INSTALL_TEST_STUB" "$INSTALL_TEST_BIN/$name"
done
export PATH="$INSTALL_TEST_BIN:/usr/bin:/bin"

run_install() {
  : >"$INSTALL_TEST_LOG"
  bash "$repo_dir/install.sh" "$@" >"$test_dir/output" 2>&1
}

require() {
  grep -Fq -- "$1" "${2:-$INSTALL_TEST_LOG}" || {
    printf 'Missing: %s\n' "$1" >&2
    exit 1
  }
}

refuse() {
  if grep -Eq -- "$1" "${2:-$INSTALL_TEST_LOG}"; then
    printf 'Unexpected match: %s\n' "$1" >&2
    exit 1
  fi
}

removed='anthropics/skills|svg-assembly-animator|emil-design-eng|gh-stack|--all'

run_install
require $'vpx\tskills\tadd\tzrr1999/skills\t'
require 'kucherenko/jscpd'
refuse "$removed|animate-expo|agent.qq.com|vibe-motion|^curl|^vp[[:space:]]"

REPO_SOURCE='fixture source with spaces' run_install web mail
require $'vpx\tskills\tadd\tfixture source with spaces\t-g'
require 'review-animations'
require $'vpx\tskills\tadd\thttps://agent.qq.com\t-g'
refuse 'animate-expo'

run_install all
require 'animate-expo'
require 'durable-objects'
require 'ruler-progress-render'
refuse "$removed"

run_install --help
[[ ! -s "$INSTALL_TEST_LOG" ]]
if run_install unknown-profile; then
  printf 'Unknown profile unexpectedly succeeded\n' >&2
  exit 1
fi
[[ ! -s "$INSTALL_TEST_LOG" ]]

if INSTALL_TEST_FAIL=1 run_install; then
  printf 'Failed install unexpectedly succeeded\n' >&2
  exit 1
fi
refuse 'Done\.' "$test_dir/output"

rm "$INSTALL_TEST_BIN/vpx"
run_install
grep -q '^curl' "$INSTALL_TEST_LOG"
require $'vpx\tskills\tadd\tzrr1999/skills\t'
