#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "${SCRIPT_DIR}/../lib" && pwd)"
source "${LIB_DIR}/log.sh"
source "${LIB_DIR}/state.sh"
source "${LIB_DIR}/chroot.sh"

: "${INSTALL_CONFIG:?INSTALL_CONFIG is required}"
load_install_config "${INSTALL_CONFIG}"
export TARGET_ROOT

if [[ -z "${EFI_PART:-}" ]]; then
  log_fatal "UEFI install requested but EFI_PART is empty."
fi

chroot_exec "pacman -S --noconfirm --needed grub efibootmgr"
chroot_exec "mkdir -p /boot/efi"
chroot_exec "grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=VibeArch --recheck"
chroot_exec "grub-mkconfig -o /boot/grub/grub.cfg"

log_info "UEFI bootloader installation complete."
