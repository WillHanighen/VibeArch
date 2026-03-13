#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "${SCRIPT_DIR}/../lib" && pwd)"
source "${LIB_DIR}/log.sh"
source "${LIB_DIR}/state.sh"

: "${INSTALL_CONFIG:?INSTALL_CONFIG is required}"
load_install_config "${INSTALL_CONFIG}"

service_packages=(
  networkmanager
  bluez
  bluez-utils
  ufw
)

arch-chroot "${TARGET_ROOT}" pacman -S --noconfirm --needed "${service_packages[@]}"
arch-chroot "${TARGET_ROOT}" systemctl enable NetworkManager.service
arch-chroot "${TARGET_ROOT}" systemctl enable bluetooth.service
arch-chroot "${TARGET_ROOT}" systemctl enable greetd.service
arch-chroot "${TARGET_ROOT}" systemctl enable fstrim.timer

arch-chroot "${TARGET_ROOT}" ufw default deny incoming
arch-chroot "${TARGET_ROOT}" ufw default allow outgoing
arch-chroot "${TARGET_ROOT}" /bin/bash -lc "yes | ufw enable"

# Prefer official package if available. If not available in current mirror set, continue.
if arch-chroot "${TARGET_ROOT}" pacman -S --noconfirm --needed paru >/dev/null 2>&1; then
  log_info "Installed paru AUR helper from official repos."
else
  log_warn "paru package not available in enabled repos; skipping AUR helper install."
fi

log_info "Service and security baseline configuration complete."
