#!/usr/bin/env bash

set -euo pipefail

pass_count=0
fail_count=0

check_cmd() {
  local cmd="$1"
  if command -v "${cmd}" >/dev/null 2>&1; then
    echo "[PASS] command exists: ${cmd}"
    pass_count=$((pass_count + 1))
  else
    echo "[FAIL] command missing: ${cmd}"
    fail_count=$((fail_count + 1))
  fi
}

check_service_enabled() {
  local service="$1"
  if systemctl is-enabled "${service}" >/dev/null 2>&1; then
    echo "[PASS] service enabled: ${service}"
    pass_count=$((pass_count + 1))
  else
    echo "[FAIL] service not enabled: ${service}"
    fail_count=$((fail_count + 1))
  fi
}

check_file() {
  local path="$1"
  if [[ -f "${path}" ]]; then
    echo "[PASS] file exists: ${path}"
    pass_count=$((pass_count + 1))
  else
    echo "[FAIL] file missing: ${path}"
    fail_count=$((fail_count + 1))
  fi
}

echo "Running VibeArch install validation..."
check_cmd Hyprland
check_cmd waybar
check_cmd rofi
check_cmd kitty
check_cmd zsh
check_cmd nmcli
check_cmd pipewire
check_cmd paru

check_service_enabled NetworkManager.service
check_service_enabled greetd.service
check_service_enabled bluetooth.service
check_service_enabled ufw.service

check_file /etc/greetd/config.toml
check_file /etc/sudoers.d/10-wheel

echo
echo "Validation summary: ${pass_count} passed, ${fail_count} failed."
if ((fail_count > 0)); then
  exit 1
fi
