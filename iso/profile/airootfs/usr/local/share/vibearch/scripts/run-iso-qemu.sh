#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT_DIR}/out"
VM_DIR="${ROOT_DIR}/tmp/vm"
DISK_PATH="${VM_DIR}/vibearch-test.qcow2"
RAM_MB="${RAM_MB:-4096}"
CPUS="${CPUS:-4}"
DISK_GB="${DISK_GB:-32}"
BOOT_MODE="${BOOT_MODE:-uefi}" # uefi|bios
DRY_RUN=0
QEMU_DISPLAY="${QEMU_DISPLAY:-gtk}"
QEMU_GL="${QEMU_GL:-off}"
QEMU_VGA="${QEMU_VGA:-std}" # std|virtio|qxl
FORCE_TCG="${FORCE_TCG:-0}"
RESET_OVMF="${RESET_OVMF:-0}"
DEBUG_SERIAL="${DEBUG_SERIAL:-0}"

usage() {
  cat <<'EOF'
Usage: bash scripts/run-iso-qemu.sh [--iso /path/to.iso] [--boot uefi|bios] [--dry-run]

Environment overrides:
  RAM_MB=4096   Memory in MB
  CPUS=4        vCPU count
  DISK_GB=32    qcow2 disk size in GB
  BOOT_MODE=uefi|bios
  QEMU_DISPLAY=gtk|sdl
  QEMU_GL=off|on
  QEMU_VGA=std|virtio|qxl
  FORCE_TCG=1   Disable KVM and use software emulation
  RESET_OVMF=1  Recreate OVMF_VARS.fd
  DEBUG_SERIAL=1  Attach serial console to terminal
  --dry-run   Print resolved QEMU config and exit
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

latest_iso() {
  ls -1t "${OUT_DIR}"/*.iso 2>/dev/null | awk 'NR==1{print; exit}'
}

detect_ovmf_code() {
  local candidates=(
    "/usr/share/OVMF/OVMF_CODE.fd"
    "/usr/share/OVMF/OVMF_CODE_4M.fd"
    "/usr/share/edk2-ovmf/x64/OVMF_CODE.fd"
    "/usr/share/edk2-ovmf/x64/OVMF_CODE_4M.fd"
    "/usr/share/edk2/x64/OVMF_CODE.fd"
    "/usr/share/edk2/x64/OVMF_CODE_4M.fd"
  )
  local p
  for p in "${candidates[@]}"; do
    if [[ -f "${p}" ]]; then
      echo "${p}"
      return 0
    fi
  done
  return 1
}

detect_ovmf_vars_template() {
  local candidates=(
    "/usr/share/OVMF/OVMF_VARS.fd"
    "/usr/share/OVMF/OVMF_VARS_4M.fd"
    "/usr/share/edk2-ovmf/x64/OVMF_VARS.fd"
    "/usr/share/edk2-ovmf/x64/OVMF_VARS_4M.fd"
    "/usr/share/edk2/x64/OVMF_VARS.fd"
    "/usr/share/edk2/x64/OVMF_VARS_4M.fd"
  )
  local p
  for p in "${candidates[@]}"; do
    if [[ -f "${p}" ]]; then
      echo "${p}"
      return 0
    fi
  done
  return 1
}

main() {
  require_cmd qemu-system-x86_64
  require_cmd qemu-img

  local iso_path=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --iso)
        iso_path="${2:-}"
        shift 2
        ;;
      --boot)
        BOOT_MODE="${2:-}"
        shift 2
        ;;
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown argument: $1" >&2
        usage
        exit 1
        ;;
    esac
  done

  if [[ -z "${iso_path}" ]]; then
    iso_path="$(latest_iso)"
  fi

  if [[ -z "${iso_path}" || ! -f "${iso_path}" ]]; then
    echo "Could not find ISO. Provide one with --iso or build first." >&2
    exit 1
  fi

  mkdir -p "${VM_DIR}"
  if [[ ! -f "${DISK_PATH}" ]]; then
    qemu-img create -f qcow2 "${DISK_PATH}" "${DISK_GB}G"
  fi

  local qemu_args=(
    -m "${RAM_MB}"
    -smp "${CPUS}"
    -drive "if=virtio,file=${DISK_PATH},format=qcow2"
    -cdrom "${iso_path}"
    -boot "order=d,menu=on"
    -netdev user,id=net0,hostfwd=tcp::2222-:22
    -device virtio-net-pci,netdev=net0
  )

  if [[ "${FORCE_TCG}" == "1" || ! -r /dev/kvm || ! -w /dev/kvm ]]; then
    qemu_args+=(-machine "q35,accel=tcg" -cpu max)
  else
    qemu_args+=(-machine "q35,accel=kvm:tcg" -cpu host)
  fi

  qemu_args+=(-display "${QEMU_DISPLAY},gl=${QEMU_GL}")
  case "${QEMU_VGA}" in
  std|virtio|qxl)
    qemu_args+=(-vga "${QEMU_VGA}")
    ;;
  *)
    echo "Invalid QEMU_VGA=${QEMU_VGA}. Use std, virtio, or qxl." >&2
    exit 1
    ;;
  esac

  if [[ "${DEBUG_SERIAL}" == "1" ]]; then
    qemu_args+=(-serial mon:stdio)
  fi

  if [[ "${BOOT_MODE}" == "uefi" ]]; then
    local ovmf_code ovmf_vars_template ovmf_vars
    ovmf_code="$(detect_ovmf_code || true)"
    ovmf_vars_template="$(detect_ovmf_vars_template || true)"
    if [[ -z "${ovmf_code}" || -z "${ovmf_vars_template}" ]]; then
      echo "UEFI mode requested but OVMF firmware files were not found." >&2
      echo "Install OVMF/edk2-ovmf packages on your host." >&2
      exit 1
    fi
    ovmf_vars="${VM_DIR}/OVMF_VARS.fd"
    if [[ "${RESET_OVMF}" == "1" ]]; then
      rm -f "${ovmf_vars}"
    fi
    if [[ ! -f "${ovmf_vars}" ]]; then
      cp "${ovmf_vars_template}" "${ovmf_vars}"
    fi
    qemu_args+=(
      -drive "if=pflash,format=raw,readonly=on,file=${ovmf_code}"
      -drive "if=pflash,format=raw,file=${ovmf_vars}"
    )
    echo "  OVMF code: ${ovmf_code}"
    echo "  OVMF vars: ${ovmf_vars}"
  elif [[ "${BOOT_MODE}" != "bios" ]]; then
    echo "Invalid boot mode: ${BOOT_MODE}. Use uefi or bios." >&2
    exit 1
  fi

  echo "Launching QEMU:"
  echo "  ISO: ${iso_path}"
  echo "  Disk: ${DISK_PATH}"
  echo "  Boot mode: ${BOOT_MODE}"
  echo "  Display: ${QEMU_DISPLAY} (gl=${QEMU_GL})"
  echo "  VGA: ${QEMU_VGA}"
  echo "  Accel: $(if [[ "${FORCE_TCG}" == "1" || ! -r /dev/kvm || ! -w /dev/kvm ]]; then echo tcg; else echo kvm:tcg; fi)"
  if [[ "${DRY_RUN}" == "1" ]]; then
    echo "Dry run requested; not launching QEMU."
    exit 0
  fi
  qemu-system-x86_64 "${qemu_args[@]}"
}

main "$@"
