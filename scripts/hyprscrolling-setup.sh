#!/usr/bin/env bash

set -euo pipefail

REPO_URL="https://github.com/hyprwm/hyprland-plugins"
PLUGIN_NAME="hyprscrolling"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/vibearch"
STATE_FILE="${STATE_DIR}/hyprscrolling-ready"
LOG_FILE="/tmp/vibearch-hyprscrolling.log"

mkdir -p "${STATE_DIR}"
touch "${LOG_FILE}" 2>/dev/null || true

if ! command -v hyprpm >/dev/null 2>&1; then
  exit 0
fi

# Fast path for subsequent launches.
if [[ -f "${STATE_FILE}" ]]; then
  hyprctl keyword general:layout scrolling >/dev/null 2>&1 || true
  exit 0
fi

{
  echo "---- $(date -Iseconds) setting up ${PLUGIN_NAME}"

  if ! hyprpm list 2>/dev/null | grep -qi "hyprland-plugins"; then
    yes | hyprpm add "${REPO_URL}" || true
  fi

  hyprpm update || true
  hyprpm enable "${PLUGIN_NAME}" || true
  hyprctl keyword general:layout scrolling || true

  touch "${STATE_FILE}"
} >>"${LOG_FILE}" 2>&1
