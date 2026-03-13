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

base_packages=(
  base
  linux
  linux-firmware
  sudo
  grub
  networkmanager
  base-devel
  git
  neovim
  vim
  curl
  wget
  less
  man-db
  man-pages
  openssh
  bash-completion
  zsh
)

case "${CPU_VENDOR}" in
amd)
  base_packages+=(amd-ucode)
  ;;
intel)
  base_packages+=(intel-ucode)
  ;;
*)
  log_warn "Unknown CPU vendor; skipping microcode package."
  ;;
esac

log_info "Installing base system via pacstrap."
pacstrap -K "${TARGET_ROOT}" "${base_packages[@]}"

# Ensure pacman defaults are usable on the installed system.
pacman_conf="${TARGET_ROOT}/etc/pacman.conf"
mirrorlist="${TARGET_ROOT}/etc/pacman.d/mirrorlist"

if [[ -f "${pacman_conf}" ]]; then
  if grep -q '^#\[multilib\]' "${pacman_conf}"; then
    sed -i '/^#\[multilib\]/{s/^#//; n; s/^#//;}' "${pacman_conf}"
  elif ! grep -q '^\[multilib\]' "${pacman_conf}"; then
    cat >>"${pacman_conf}" <<'EOF'

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF
  fi
fi

if [[ ! -f "${mirrorlist}" ]] || ! grep -Eq '^[[:space:]]*Server[[:space:]]*=' "${mirrorlist}"; then
  mkdir -p "${TARGET_ROOT}/etc/pacman.d"
  cat >"${mirrorlist}" <<'EOF'
## VibeArch defaults: leave at least one mirror enabled.
Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
Server = https://fastly.mirror.pkgbuild.com/$repo/os/$arch
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
EOF
fi

chroot_exec "mkdir -p /etc/pacman.d/gnupg && chmod 700 /etc/pacman.d/gnupg && chown -R root:root /etc/pacman.d/gnupg"
chroot_exec "if [[ ! -s /etc/pacman.d/gnupg/pubring.gpg ]]; then rm -f /etc/pacman.d/gnupg/*.lock || true; pacman-key --init; pacman-key --populate archlinux; fi"

log_info "Generating fstab."
genfstab -U "${TARGET_ROOT}" >>"${TARGET_ROOT}/etc/fstab"

if [[ "${SWAP_STRATEGY}" == "swapfile" ]]; then
  if ! grep -q "/swapfile" "${TARGET_ROOT}/etc/fstab"; then
    echo "/swapfile none swap defaults 0 0" >>"${TARGET_ROOT}/etc/fstab"
  fi
fi

if [[ ! -f "${TARGET_ROOT}/etc/locale.gen" ]]; then
  log_fatal "Missing ${TARGET_ROOT}/etc/locale.gen after pacstrap."
fi

if ! grep -q "^${LOCALE} " "${TARGET_ROOT}/etc/locale.gen"; then
  echo "${LOCALE} UTF-8" >>"${TARGET_ROOT}/etc/locale.gen"
fi

chroot_exec "ln -sf '/usr/share/zoneinfo/${TIMEZONE}' /etc/localtime"
chroot_exec "hwclock --systohc"
chroot_exec "locale-gen"
chroot_exec "printf 'LANG=%s\n' '${LOCALE}' > /etc/locale.conf"
chroot_exec "printf 'KEYMAP=%s\n' '${KEYMAP}' > /etc/vconsole.conf"
chroot_exec "printf '%s\n' '${HOSTNAME}' > /etc/hostname"
chroot_exec "cat > /etc/hosts <<'EOF'
127.0.0.1 localhost
::1 localhost
127.0.1.1 ${HOSTNAME}.localdomain ${HOSTNAME}
EOF"

chroot_exec "echo 'root:${ROOT_PASSWORD}' | chpasswd"
chroot_exec "mkinitcpio -P"

log_info "Base system configured."
