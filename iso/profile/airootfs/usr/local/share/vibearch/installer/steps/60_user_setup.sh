#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "${SCRIPT_DIR}/../lib" && pwd)"
source "${LIB_DIR}/log.sh"
source "${LIB_DIR}/state.sh"

: "${INSTALL_CONFIG:?INSTALL_CONFIG is required}"
load_install_config "${INSTALL_CONFIG}"

arch-chroot "${TARGET_ROOT}" /bin/bash -lc "id -u '${USERNAME}' >/dev/null 2>&1 || useradd -m -G wheel,audio,video,storage,input -s /usr/bin/zsh '${USERNAME}'"
arch-chroot "${TARGET_ROOT}" /bin/bash -lc "usermod -s /usr/bin/zsh '${USERNAME}' >/dev/null 2>&1 || true"
arch-chroot "${TARGET_ROOT}" /bin/bash -lc "echo '${USERNAME}:${USER_PASSWORD}' | chpasswd"
arch-chroot "${TARGET_ROOT}" /bin/bash -lc "mkdir -p /etc/sudoers.d"
arch-chroot "${TARGET_ROOT}" /bin/bash -lc "cat > /etc/sudoers.d/10-wheel <<'EOF'
%wheel ALL=(ALL:ALL) ALL
EOF"
arch-chroot "${TARGET_ROOT}" chmod 0440 /etc/sudoers.d/10-wheel

# Ensure default config payload lands in user home if skel copy did not happen.
if [[ -d "${TARGET_ROOT}/etc/skel/.config" ]]; then
  arch-chroot "${TARGET_ROOT}" /bin/bash -lc "cp -rn /etc/skel/.config '/home/${USERNAME}/'"
  arch-chroot "${TARGET_ROOT}" chown -R "${USERNAME}:${USERNAME}" "/home/${USERNAME}/.config"
fi

arch-chroot "${TARGET_ROOT}" /bin/bash -lc "if [[ -x /usr/local/share/vibearch/scripts/setup-zsh-defaults.sh ]]; then /usr/local/share/vibearch/scripts/setup-zsh-defaults.sh --user '${USERNAME}'; fi"

log_info "Primary user setup complete."
