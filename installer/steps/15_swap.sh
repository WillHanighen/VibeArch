#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "${SCRIPT_DIR}/../lib" && pwd)"
source "${LIB_DIR}/log.sh"
source "${LIB_DIR}/state.sh"

: "${INSTALL_CONFIG:?INSTALL_CONFIG is required}"
load_install_config "${INSTALL_CONFIG}"

case "${SWAP_STRATEGY}" in
none)
  log_info "Swap disabled by user choice."
  ;;
swapfile)
  log_info "Creating swapfile (${SWAP_SIZE_GIB} GiB) at ${TARGET_ROOT}/swapfile"
  if ! fallocate -l "${SWAP_SIZE_GIB}G" "${TARGET_ROOT}/swapfile"; then
    dd if=/dev/zero of="${TARGET_ROOT}/swapfile" bs=1M count="$((SWAP_SIZE_GIB * 1024))" status=progress
  fi
  chmod 600 "${TARGET_ROOT}/swapfile"
  mkswap "${TARGET_ROOT}/swapfile"
  swapon "${TARGET_ROOT}/swapfile"
  ;;
swap-partition)
  if [[ -n "${SWAP_PART:-}" ]]; then
    log_info "Initializing swap partition ${SWAP_PART}"
    mkswap "${SWAP_PART}"
    swapon "${SWAP_PART}"
  else
    log_warn "Swap partition strategy selected but no swap partition was created."
  fi
  ;;
*)
  log_fatal "Unknown SWAP_STRATEGY: ${SWAP_STRATEGY}"
  ;;
esac
