#!/usr/bin/env bash
# Run before the agent loads its skill catalog, never as a background cron job.
set -euo pipefail
pilot_scripts="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# Setup is idempotent: it restores missing tools/dependencies and refreshes skills.
exec bash "$pilot_scripts/setup.sh" "$@"
