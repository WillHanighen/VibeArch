#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "${SCRIPT_DIR}/../lib" && pwd)"
source "${LIB_DIR}/log.sh"
source "${LIB_DIR}/state.sh"

: "${INSTALL_CONFIG:?INSTALL_CONFIG is required}"
load_install_config "${INSTALL_CONFIG}"

arch-chroot "${TARGET_ROOT}" pacman -S --noconfirm --needed greetd greetd-tuigreet
arch-chroot "${TARGET_ROOT}" /bin/bash -lc "mkdir -p /etc/greetd"
arch-chroot "${TARGET_ROOT}" /bin/bash -lc "cat > /etc/greetd/config.toml <<'EOF'
[terminal]
vt = 1

[default_session]
command = \"tuigreet --time --remember --cmd Hyprland\"
user = \"greeter\"
EOF"

log_info "greetd + tuigreet configuration complete."
