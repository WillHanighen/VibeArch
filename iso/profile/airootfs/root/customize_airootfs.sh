#!/usr/bin/env bash

set -euo pipefail

# Brand the live environment.
echo "vibearch" >/etc/hostname
cat >/etc/issue <<'EOF'
VibeArch \r (\l)

EOF

# Disable firstboot interactive prompts in live ISO.
mkdir -p /etc/systemd/system
ln -sf /dev/null /etc/systemd/system/systemd-firstboot.service

# Make pacman usable out of the box in the live ISO.
if [[ -f /etc/pacman.conf ]]; then
  if grep -q '^#\[multilib\]' /etc/pacman.conf; then
    sed -i '/^#\[multilib\]/{s/^#//; n; s/^#//;}' /etc/pacman.conf
  elif ! grep -q '^\[multilib\]' /etc/pacman.conf; then
    cat >>/etc/pacman.conf <<'EOF'

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF
  fi
fi

mkdir -p /etc/pacman.d
if [[ ! -f /etc/pacman.d/mirrorlist ]] || ! grep -Eq '^[[:space:]]*Server[[:space:]]*=' /etc/pacman.d/mirrorlist; then
  cat >/etc/pacman.d/mirrorlist <<'EOF'
## VibeArch defaults: leave at least one mirror enabled.
Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
Server = https://fastly.mirror.pkgbuild.com/$repo/os/$arch
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
EOF
fi

# Make sure pacman keyring exists and is writable.
mkdir -p /etc/pacman.d/gnupg
chmod 700 /etc/pacman.d/gnupg || true
chown -R root:root /etc/pacman.d/gnupg || true
if [[ ! -s /etc/pacman.d/gnupg/pubring.gpg ]]; then
  rm -f /etc/pacman.d/gnupg/*.lock || true
  if command -v pacman-key >/dev/null 2>&1; then
    pacman-key --init || true
    pacman-key --populate archlinux || true
  fi
fi

# Brand os-release fields for console/banner consumers.
if [[ -f /etc/os-release ]]; then
  sed -i 's/^NAME=.*/NAME="VibeArch"/' /etc/os-release || true
  sed -i 's/^PRETTY_NAME=.*/PRETTY_NAME="VibeArch"/' /etc/os-release || true
  sed -i 's/^ID=.*/ID=vibearch/' /etc/os-release || true
  sed -i 's|^HOME_URL=.*|HOME_URL="https://github.com/cottage-ubu/VibeArch"|' /etc/os-release || true
fi

if [[ -f /usr/lib/os-release ]]; then
  sed -i 's/^NAME=.*/NAME="VibeArch"/' /usr/lib/os-release || true
  sed -i 's/^PRETTY_NAME=.*/PRETTY_NAME="VibeArch"/' /usr/lib/os-release || true
  sed -i 's/^ID=.*/ID=vibearch/' /usr/lib/os-release || true
  sed -i 's|^HOME_URL=.*|HOME_URL="https://github.com/cottage-ubu/VibeArch"|' /usr/lib/os-release || true
fi
