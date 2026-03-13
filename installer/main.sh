#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"
STEP_DIR="${SCRIPT_DIR}/steps"

source "${LIB_DIR}/log.sh"
source "${LIB_DIR}/ui.sh"
source "${LIB_DIR}/hardware.sh"
source "${LIB_DIR}/state.sh"

export VIBEARCH_STATE_DIR="${VIBEARCH_STATE_DIR:-/tmp/vibearch-installer}"
export INSTALL_CONFIG="${VIBEARCH_STATE_DIR}/install.conf"
export TARGET_ROOT="/mnt"

mkdir -p "${VIBEARCH_STATE_DIR}"
touch "${INSTALL_CONFIG}"

trap 'log_error "Installer failed at line ${LINENO}. See ${VIBEARCH_LOG_FILE}."' ERR

select_target_disk() {
  mapfile -t disk_lines < <(lsblk -dpno NAME,SIZE,MODEL | sed 's/[[:space:]]\+/ /g')
  if [[ "${#disk_lines[@]}" -eq 0 ]]; then
    log_fatal "No block devices found."
  fi

  local options=()
  local line disk_name disk_desc
  for line in "${disk_lines[@]}"; do
    disk_name="${line%% *}"
    disk_desc="${line#* }"
    options+=("${disk_name}::${disk_desc}")
  done

  ui_menu "Target Disk" "Select target install disk (WILL BE ERASED)." "${options[@]}"
}

prompt_password_pair() {
  local label="$1"
  local pass1 pass2

  while true; do
    pass1="$(ui_password "Enter ${label}")"
    pass2="$(ui_password "Confirm ${label}")"
    if [[ -n "${pass1}" && "${pass1}" == "${pass2}" ]]; then
      echo "${pass1}"
      return 0
    fi
    ui_message "${label} did not match. Try again."
  done
}

collect_inputs() {
  local target_disk hostname username timezone locale keymap
  local swap_strategy swap_size_gib user_password root_password
  local firmware_mode gpu_profile cpu_vendor nvidia_driver

  firmware_mode="$(detect_firmware_mode)"
  gpu_profile="$(detect_gpu_profile)"
  cpu_vendor="$(detect_cpu_vendor)"
  nvidia_driver="none"
  if [[ "${gpu_profile}" == "nvidia" || "${gpu_profile}" == "hybrid" ]]; then
    if nvidia_open_supported; then
      nvidia_driver="nvidia-open"
    else
      nvidia_driver="nvidia"
    fi
  fi

  target_disk="$(select_target_disk)"
  hostname="$(ui_input "Hostname" "vibearch")"
  username="$(ui_input "Primary username" "vibe")"
  timezone="$(ui_input "Timezone (e.g. UTC, Europe/London)" "UTC")"
  locale="$(ui_input "Locale" "en_US.UTF-8")"
  keymap="$(ui_input "Console keymap" "us")"

  swap_strategy="$(ui_menu "Swap Strategy" "Select swap strategy." \
    "none::No swap" \
    "swapfile::Create swapfile on root filesystem" \
    "swap-partition::Create dedicated swap partition")"

  swap_size_gib="0"
  if [[ "${swap_strategy}" != "none" ]]; then
    swap_size_gib="$(ui_input "Swap size in GiB" "4")"
  fi

  user_password="$(prompt_password_pair "user password")"
  if ui_confirm "Use the same password for root?"; then
    root_password="${user_password}"
  else
    root_password="$(prompt_password_pair "root password")"
  fi

  local summary
  summary=$(
    cat <<EOF
Disk: ${target_disk}
Hostname: ${hostname}
Username: ${username}
Timezone: ${timezone}
Locale: ${locale}
Keymap: ${keymap}
Swap: ${swap_strategy} (${swap_size_gib} GiB)
Firmware: ${firmware_mode}
GPU profile: ${gpu_profile}
NVIDIA path: ${nvidia_driver}
EOF
  )

  if ! ui_confirm "$(printf "Proceed with installation?\n\n%s" "${summary}")"; then
    log_fatal "Installation cancelled by user."
  fi

  : >"${INSTALL_CONFIG}"
  save_config_var "${INSTALL_CONFIG}" "TARGET_DISK" "${target_disk}"
  save_config_var "${INSTALL_CONFIG}" "HOSTNAME" "${hostname}"
  save_config_var "${INSTALL_CONFIG}" "USERNAME" "${username}"
  save_config_var "${INSTALL_CONFIG}" "TIMEZONE" "${timezone}"
  save_config_var "${INSTALL_CONFIG}" "LOCALE" "${locale}"
  save_config_var "${INSTALL_CONFIG}" "KEYMAP" "${keymap}"
  save_config_var "${INSTALL_CONFIG}" "SWAP_STRATEGY" "${swap_strategy}"
  save_config_var "${INSTALL_CONFIG}" "SWAP_SIZE_GIB" "${swap_size_gib}"
  save_config_var "${INSTALL_CONFIG}" "USER_PASSWORD" "${user_password}"
  save_config_var "${INSTALL_CONFIG}" "ROOT_PASSWORD" "${root_password}"
  save_config_var "${INSTALL_CONFIG}" "FIRMWARE_MODE" "${firmware_mode}"
  save_config_var "${INSTALL_CONFIG}" "GPU_PROFILE" "${gpu_profile}"
  save_config_var "${INSTALL_CONFIG}" "CPU_VENDOR" "${cpu_vendor}"
  save_config_var "${INSTALL_CONFIG}" "NVIDIA_DRIVER" "${nvidia_driver}"
  save_config_var "${INSTALL_CONFIG}" "TARGET_ROOT" "${TARGET_ROOT}"

  log_info "Saved installer configuration to ${INSTALL_CONFIG}"
}

run_step() {
  local step_script="$1"
  if [[ ! -f "${step_script}" ]]; then
    log_fatal "Missing installer step: ${step_script}"
  fi
  log_info "Starting step: $(basename "${step_script}")"
  INSTALL_CONFIG="${INSTALL_CONFIG}" bash "${step_script}"
  log_info "Completed step: $(basename "${step_script}")"
}

main() {
  require_cmd lsblk
  require_cmd pacstrap
  require_cmd arch-chroot

  run_step "${STEP_DIR}/05_preflight.sh"
  collect_inputs

  run_step "${STEP_DIR}/10_disk_ext4.sh"
  run_step "${STEP_DIR}/15_swap.sh"
  run_step "${STEP_DIR}/20_base_arch.sh"

  load_install_config "${INSTALL_CONFIG}"
  if [[ "${FIRMWARE_MODE}" == "uefi" ]]; then
    run_step "${STEP_DIR}/30_bootloader_uefi.sh"
  else
    run_step "${STEP_DIR}/31_bootloader_bios.sh"
  fi

  run_step "${STEP_DIR}/40_gpu_stack.sh"
  run_step "${STEP_DIR}/50_hyprland_stack.sh"
  run_step "${STEP_DIR}/55_login_manager.sh"
  run_step "${STEP_DIR}/60_user_setup.sh"
  run_step "${STEP_DIR}/70_services.sh"
  run_step "${STEP_DIR}/80_finalize.sh"
}

main "$@"
