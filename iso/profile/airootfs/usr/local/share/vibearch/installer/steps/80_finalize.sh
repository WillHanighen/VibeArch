#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "${SCRIPT_DIR}/../lib" && pwd)"
source "${LIB_DIR}/log.sh"
source "${LIB_DIR}/state.sh"
source "${LIB_DIR}/ui.sh"

: "${INSTALL_CONFIG:?INSTALL_CONFIG is required}"
load_install_config "${INSTALL_CONFIG}"

summary_file="${VIBEARCH_STATE_DIR}/summary.txt"
cat >"${summary_file}" <<EOF
VibeArch installation complete.

Disk: ${TARGET_DISK}
Root partition: ${ROOT_PART}
EFI partition: ${EFI_PART:-n/a}
Swap strategy: ${SWAP_STRATEGY}
Firmware: ${FIRMWARE_MODE}
GPU profile: ${GPU_PROFILE}
NVIDIA driver path: ${NVIDIA_DRIVER}
Primary user: ${USERNAME}
Hostname: ${HOSTNAME}

Next steps:
1. Reboot the system.
2. Remove installation media.
3. Login via greetd and start using Hyprland.
EOF

cp "${summary_file}" "${TARGET_ROOT}/root/vibearch-install-summary.txt"
ui_message "Install complete.\n\nSummary saved to:\n${summary_file}\n${TARGET_ROOT}/root/vibearch-install-summary.txt"
log_info "Finalization complete."
