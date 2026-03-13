#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "${SCRIPT_DIR}/../lib" && pwd)"
source "${LIB_DIR}/log.sh"
source "${LIB_DIR}/state.sh"

: "${INSTALL_CONFIG:?INSTALL_CONFIG is required}"
load_install_config "${INSTALL_CONFIG}"

install_target_packages() {
  local pkgs=("$@")
  if [[ "${#pkgs[@]}" -eq 0 ]]; then
    return 0
  fi
  log_info "Installing GPU packages: ${pkgs[*]}"
  arch-chroot "${TARGET_ROOT}" pacman -S --noconfirm --needed "${pkgs[@]}"
}

common_gpu_pkgs=(mesa vulkan-icd-loader mesa-utils libva-utils)

case "${GPU_PROFILE}" in
amd)
  install_target_packages "${common_gpu_pkgs[@]}" vulkan-radeon xf86-video-amdgpu
  ;;
intel)
  install_target_packages "${common_gpu_pkgs[@]}" vulkan-intel intel-media-driver
  ;;
nvidia)
  if [[ "${NVIDIA_DRIVER}" == "nvidia-open" ]]; then
    install_target_packages "${common_gpu_pkgs[@]}" nvidia-open nvidia-utils nvidia-settings libva-nvidia-driver
  else
    install_target_packages "${common_gpu_pkgs[@]}" nvidia nvidia-utils nvidia-settings libva-nvidia-driver
  fi
  ;;
hybrid)
  if [[ "${NVIDIA_DRIVER}" == "nvidia-open" ]]; then
    install_target_packages "${common_gpu_pkgs[@]}" vulkan-intel intel-media-driver nvidia-open nvidia-utils nvidia-settings libva-nvidia-driver
  else
    install_target_packages "${common_gpu_pkgs[@]}" vulkan-intel intel-media-driver nvidia nvidia-utils nvidia-settings libva-nvidia-driver
  fi
  ;;
*)
  log_warn "Unknown GPU profile (${GPU_PROFILE}). Installing Mesa baseline only."
  install_target_packages "${common_gpu_pkgs[@]}"
  ;;
esac

if [[ "${GPU_PROFILE}" == "nvidia" || "${GPU_PROFILE}" == "hybrid" ]]; then
  arch-chroot "${TARGET_ROOT}" /bin/bash -lc "mkdir -p /etc/modprobe.d"
  arch-chroot "${TARGET_ROOT}" /bin/bash -lc "cat > /etc/modprobe.d/nvidia.conf <<'EOF'
options nvidia_drm modeset=1
EOF"
fi

log_info "GPU stack step complete."
