#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "${SCRIPT_DIR}/../lib" && pwd)"
source "${LIB_DIR}/log.sh"
source "${LIB_DIR}/state.sh"

: "${INSTALL_CONFIG:?INSTALL_CONFIG is required}"
load_install_config "${INSTALL_CONFIG}"

desktop_packages=(
  hyprland
  hyprland-protocols
  xdg-desktop-portal-hyprland
  xdg-desktop-portal-gtk
  waybar
  rofi-wayland
  foot
  kitty
  dunst
  fastfetch
  thunar
  thunar-volman
  tumbler
  grim
  slurp
  wl-clipboard
  pavucontrol
  pamixer
  brightnessctl
  playerctl
  network-manager-applet
  polkit-gnome
  qt5-wayland
  qt6-wayland
  firefox
  ttf-dejavu
  noto-fonts
  noto-fonts-emoji
  pipewire
  pipewire-pulse
  wireplumber
  zsh-autosuggestions
  zsh-completions
  zsh-syntax-highlighting
  cpio
  cmake
  glaze
  meson
)

log_info "Installing Hyprland desktop stack."
arch-chroot "${TARGET_ROOT}" pacman -S --noconfirm --needed "${desktop_packages[@]}"

if [[ -d /usr/local/share/vibearch/config ]]; then
  log_info "Copying default desktop configs to /etc/skel/.config"
  mkdir -p "${TARGET_ROOT}/etc/skel/.config"
  cp -r /usr/local/share/vibearch/config/* "${TARGET_ROOT}/etc/skel/.config/"
fi

if [[ -d /usr/local/share/vibearch/scripts ]]; then
  log_info "Copying VibeArch helper scripts to target system"
  mkdir -p "${TARGET_ROOT}/usr/local/share/vibearch/scripts"
  cp -r /usr/local/share/vibearch/scripts/* "${TARGET_ROOT}/usr/local/share/vibearch/scripts/"
  find "${TARGET_ROOT}/usr/local/share/vibearch/scripts" -type f -name "*.sh" -exec chmod +x {} \;
fi

if [[ -d /usr/local/share/vibearch/assets ]]; then
  log_info "Copying VibeArch assets to target system"
  mkdir -p "${TARGET_ROOT}/usr/local/share/vibearch/assets"
  cp -r /usr/local/share/vibearch/assets/* "${TARGET_ROOT}/usr/local/share/vibearch/assets/"
fi

if [[ -x "${TARGET_ROOT}/usr/local/share/vibearch/scripts/fastfetch-wrapper.sh" ]]; then
  log_info "Installing fastfetch wrapper"
  cp "${TARGET_ROOT}/usr/local/share/vibearch/scripts/fastfetch-wrapper.sh" "${TARGET_ROOT}/usr/local/bin/fastfetch"
  chmod +x "${TARGET_ROOT}/usr/local/bin/fastfetch"
fi

log_info "Hyprland desktop stack configured."
