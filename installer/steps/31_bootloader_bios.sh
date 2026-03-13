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

chroot_exec "pacman -S --noconfirm --needed grub"
chroot_exec "grub-install --target=i386-pc '${TARGET_DISK}' --recheck"
chroot_exec "grub-mkconfig -o /boot/grub/grub.cfg"

log_info "BIOS bootloader installation complete."
