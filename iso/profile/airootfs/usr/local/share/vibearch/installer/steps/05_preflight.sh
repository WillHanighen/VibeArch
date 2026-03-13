#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "${SCRIPT_DIR}/../lib" && pwd)"
source "${LIB_DIR}/log.sh"

require_cmd lsblk
require_cmd pacstrap
require_cmd arch-chroot
require_cmd parted
require_cmd mkfs.ext4
require_cmd timedatectl

if [[ "${EUID}" -ne 0 ]]; then
  log_fatal "Installer must run as root."
fi

log_info "Enabling NTP sync."
timedatectl set-ntp true || log_warn "Failed to enable NTP; continuing."

if ping -c 1 -W 2 archlinux.org >/dev/null 2>&1; then
  log_info "Network check passed."
else
  log_warn "Network check failed. Installation may fail when downloading packages."
fi

if mount | grep -q " on /mnt "; then
  log_warn "/mnt is already mounted. Existing mounts may be replaced by installer."
fi

log_info "Preflight checks completed."
