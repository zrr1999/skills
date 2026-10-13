#!/usr/bin/env bash
# Source this file in setup, maintenance, and new agent shells.
export VP_HOME="${VP_HOME:-$HOME/.vite-plus}"
export VP_NODE_MANAGER="${VP_NODE_MANAGER:-yes}"
export NODE_USE_ENV_PROXY="${NODE_USE_ENV_PROXY:-1}"
export SKILLS_AGENT="${SKILLS_AGENT:-cline}"
export PATH="$VP_HOME/bin:$HOME/.local/bin:$PATH"
export CLOUD_PILOT_STATE_DIR="${CLOUD_PILOT_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/cloud-pilot}"
export CLOUD_PILOT_CACHE_DIR="${CLOUD_PILOT_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/cloud-pilot}"
export CLOUD_PILOT_ROOT="${CLOUD_PILOT_ROOT:-/workspace/cloud-repos}"
