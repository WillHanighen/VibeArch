#!/usr/bin/env bash

set -euo pipefail

load_install_config() {
  local config_path="$1"
  if [[ ! -f "${config_path}" ]]; then
    return 0
  fi
  # shellcheck disable=SC1090
  source "${config_path}"
}

save_config_var() {
  local config_path="$1"
  local key="$2"
  local value="$3"

  touch "${config_path}"

  if grep -n "^${key}=" "${config_path}" >/dev/null 2>&1; then
    sed -i "s|^${key}=.*$|${key}='${value//\'/\'\"\'\"\'}'|g" "${config_path}"
  else
    printf "%s='%s'\n" "${key}" "${value//\'/\'\"\'\"\'}" >>"${config_path}"
  fi
}
