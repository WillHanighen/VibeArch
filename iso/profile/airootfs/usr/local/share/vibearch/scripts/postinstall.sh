#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_SOURCE_DIR="/usr/local/share/vibearch/config"
FALLBACK_SOURCE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)/config"

SOURCE_DIR="${1:-${DEFAULT_SOURCE_DIR}}"
TARGET_USER="${VIBEARCH_USER:-${SUDO_USER:-$(id -un)}}"

if [[ ! -d "${SOURCE_DIR}" ]]; then
  if [[ -d "${FALLBACK_SOURCE_DIR}" ]]; then
    SOURCE_DIR="${FALLBACK_SOURCE_DIR}"
  else
    echo "No config source found. Tried: ${SOURCE_DIR} and ${FALLBACK_SOURCE_DIR}" >&2
    exit 1
  fi
fi

TARGET_HOME="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"
if [[ -z "${TARGET_HOME}" ]]; then
  echo "Could not resolve home directory for user: ${TARGET_USER}" >&2
  exit 1
fi

TARGET_CONFIG_DIR="${TARGET_HOME}/.config"
mkdir -p "${TARGET_CONFIG_DIR}"

echo "Applying configs from ${SOURCE_DIR} to ${TARGET_CONFIG_DIR}"
rsync -a --delete "${SOURCE_DIR}/hypr/" "${TARGET_CONFIG_DIR}/hypr/"
rsync -a --delete "${SOURCE_DIR}/waybar/" "${TARGET_CONFIG_DIR}/waybar/"
rsync -a --delete "${SOURCE_DIR}/rofi/" "${TARGET_CONFIG_DIR}/rofi/"
if [[ -d "${SOURCE_DIR}/kitty" ]]; then
  rsync -a --delete "${SOURCE_DIR}/kitty/" "${TARGET_CONFIG_DIR}/kitty/"
fi

if [[ "${EUID}" -eq 0 ]]; then
  chown -R "${TARGET_USER}:${TARGET_USER}" "${TARGET_CONFIG_DIR}/hypr" "${TARGET_CONFIG_DIR}/waybar" "${TARGET_CONFIG_DIR}/rofi"
  if [[ -d "${TARGET_CONFIG_DIR}/kitty" ]]; then
    chown -R "${TARGET_USER}:${TARGET_USER}" "${TARGET_CONFIG_DIR}/kitty"
  fi
fi

if [[ -x "/usr/local/share/vibearch/scripts/setup-zsh-defaults.sh" ]]; then
  /usr/local/share/vibearch/scripts/setup-zsh-defaults.sh --user "${TARGET_USER}" || true
fi

echo "Post-install config apply complete."
