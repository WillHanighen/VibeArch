#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE_DIR="${ROOT_DIR}/iso/profile"
AIROOTFS_DIR="${PROFILE_DIR}/airootfs"
ASSET_DIR="${AIROOTFS_DIR}/usr/local/share/vibearch"

WORK_DIR="${ROOT_DIR}/work"
OUT_DIR="${ROOT_DIR}/out"
CLEAN_BUILD="${VIBEARCH_CLEAN_BUILD:-1}"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

stage_profile_assets() {
  rm -rf "${ASSET_DIR}"
  mkdir -p "${ASSET_DIR}"

  cp -r "${ROOT_DIR}/installer" "${ASSET_DIR}/installer"
  cp -r "${ROOT_DIR}/config" "${ASSET_DIR}/config"
  cp -r "${ROOT_DIR}/scripts" "${ASSET_DIR}/scripts"
  cp -r "${ROOT_DIR}/docs" "${ASSET_DIR}/docs"
  cp -r "${ROOT_DIR}/assets" "${ASSET_DIR}/assets"
  cp "${ROOT_DIR}/README.md" "${ASSET_DIR}/README.md"

  chmod +x "${ASSET_DIR}/installer/main.sh"
  chmod +x "${ASSET_DIR}/scripts/"*.sh || true
  find "${ASSET_DIR}/installer/steps" -type f -name "*.sh" -exec chmod +x {} \;
  find "${ASSET_DIR}/installer/lib" -type f -name "*.sh" -exec chmod +x {} \;
}

main() {
  require_cmd mkarchiso
  require_cmd rsync

  mkdir -p "${WORK_DIR}" "${OUT_DIR}" "${AIROOTFS_DIR}/usr/local/bin"

  if [[ "${CLEAN_BUILD}" == "1" ]]; then
    echo "Cleaning previous work directory: ${WORK_DIR}"
    if [[ "${EUID}" -eq 0 ]]; then
      rm -rf "${WORK_DIR}"
    else
      sudo rm -rf "${WORK_DIR}"
    fi
    mkdir -p "${WORK_DIR}"
  fi

  stage_profile_assets

  if [[ "${EUID}" -eq 0 ]]; then
    mkarchiso -v -w "${WORK_DIR}" -o "${OUT_DIR}" "${PROFILE_DIR}"
  else
    sudo mkarchiso -v -w "${WORK_DIR}" -o "${OUT_DIR}" "${PROFILE_DIR}"
  fi
}

main "$@"
