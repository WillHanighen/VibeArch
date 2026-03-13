#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "${SCRIPT_DIR}/../lib" && pwd)"
source "${LIB_DIR}/log.sh"
source "${LIB_DIR}/state.sh"

: "${INSTALL_CONFIG:?INSTALL_CONFIG is required}"
load_install_config "${INSTALL_CONFIG}"

disk_part() {
  local disk="$1"
  local idx="$2"
  if [[ "${disk}" =~ (nvme|mmcblk|loop) ]]; then
    echo "${disk}p${idx}"
  else
    echo "${disk}${idx}"
  fi
}

require_cmd parted
require_cmd wipefs
require_cmd mkfs.ext4
require_cmd mkfs.fat
require_cmd partprobe

log_warn "Destroying partition table on ${TARGET_DISK}"
swapoff -a || true
umount -R "${TARGET_ROOT}" >/dev/null 2>&1 || true

run_cmd wipefs -af "${TARGET_DISK}"
run_cmd parted -s "${TARGET_DISK}" mklabel gpt

ROOT_PART=""
EFI_PART=""
SWAP_PART=""

if [[ "${FIRMWARE_MODE}" == "uefi" ]]; then
  run_cmd parted -s "${TARGET_DISK}" mkpart ESP fat32 1MiB 513MiB
  run_cmd parted -s "${TARGET_DISK}" set 1 esp on

  if [[ "${SWAP_STRATEGY}" == "swap-partition" && "${SWAP_SIZE_GIB}" != "0" ]]; then
    run_cmd parted -s "${TARGET_DISK}" mkpart primary ext4 513MiB "-${SWAP_SIZE_GIB}GiB"
    run_cmd parted -s "${TARGET_DISK}" mkpart primary linux-swap "-${SWAP_SIZE_GIB}GiB" 100%
    ROOT_PART="$(disk_part "${TARGET_DISK}" 2)"
    SWAP_PART="$(disk_part "${TARGET_DISK}" 3)"
  else
    run_cmd parted -s "${TARGET_DISK}" mkpart primary ext4 513MiB 100%
    ROOT_PART="$(disk_part "${TARGET_DISK}" 2)"
  fi

  EFI_PART="$(disk_part "${TARGET_DISK}" 1)"
else
  run_cmd parted -s "${TARGET_DISK}" mkpart biosboot 1MiB 3MiB
  run_cmd parted -s "${TARGET_DISK}" set 1 bios_grub on

  if [[ "${SWAP_STRATEGY}" == "swap-partition" && "${SWAP_SIZE_GIB}" != "0" ]]; then
    run_cmd parted -s "${TARGET_DISK}" mkpart primary ext4 3MiB "-${SWAP_SIZE_GIB}GiB"
    run_cmd parted -s "${TARGET_DISK}" mkpart primary linux-swap "-${SWAP_SIZE_GIB}GiB" 100%
    ROOT_PART="$(disk_part "${TARGET_DISK}" 2)"
    SWAP_PART="$(disk_part "${TARGET_DISK}" 3)"
  else
    run_cmd parted -s "${TARGET_DISK}" mkpart primary ext4 3MiB 100%
    ROOT_PART="$(disk_part "${TARGET_DISK}" 2)"
  fi
fi

run_cmd partprobe "${TARGET_DISK}"
sleep 2

run_cmd mkfs.ext4 -F "${ROOT_PART}"
run_cmd mount "${ROOT_PART}" "${TARGET_ROOT}"

if [[ "${FIRMWARE_MODE}" == "uefi" ]]; then
  run_cmd mkfs.fat -F32 "${EFI_PART}"
  run_cmd mkdir -p "${TARGET_ROOT}/boot/efi"
  run_cmd mount "${EFI_PART}" "${TARGET_ROOT}/boot/efi"
fi

save_config_var "${INSTALL_CONFIG}" "ROOT_PART" "${ROOT_PART}"
save_config_var "${INSTALL_CONFIG}" "EFI_PART" "${EFI_PART}"
save_config_var "${INSTALL_CONFIG}" "SWAP_PART" "${SWAP_PART}"

log_info "Disk layout complete. ROOT_PART=${ROOT_PART} EFI_PART=${EFI_PART} SWAP_PART=${SWAP_PART}"
