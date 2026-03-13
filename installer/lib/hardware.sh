#!/usr/bin/env bash

set -euo pipefail

detect_firmware_mode() {
  if [[ -d /sys/firmware/efi ]]; then
    echo "uefi"
  else
    echo "bios"
  fi
}

detect_cpu_vendor() {
  if grep -qi "AuthenticAMD" /proc/cpuinfo; then
    echo "amd"
    return 0
  fi

  if grep -qi "GenuineIntel" /proc/cpuinfo; then
    echo "intel"
    return 0
  fi

  echo "unknown"
}

detect_gpu_profile() {
  local lspci_out
  lspci_out="$(lspci -nnk | tr '[:upper:]' '[:lower:]')"

  local has_nvidia="0"
  local has_amd="0"
  local has_intel="0"

  if [[ "${lspci_out}" == *"nvidia"* ]]; then
    has_nvidia="1"
  fi
  if [[ "${lspci_out}" == *"advanced micro devices"* || "${lspci_out}" == *"amd/ati"* ]]; then
    has_amd="1"
  fi
  if [[ "${lspci_out}" == *"intel corporation"* ]]; then
    has_intel="1"
  fi

  if [[ "${has_nvidia}" == "1" && ( "${has_amd}" == "1" || "${has_intel}" == "1" ) ]]; then
    echo "hybrid"
    return 0
  fi

  if [[ "${has_nvidia}" == "1" ]]; then
    echo "nvidia"
    return 0
  fi

  if [[ "${has_amd}" == "1" ]]; then
    echo "amd"
    return 0
  fi

  if [[ "${has_intel}" == "1" ]]; then
    echo "intel"
    return 0
  fi

  echo "unknown"
}

nvidia_open_supported() {
  local lspci_out
  lspci_out="$(lspci | tr '[:upper:]' '[:lower:]')"

  # Conservative fallback for older generations where open modules are usually not ideal.
  if [[ "${lspci_out}" =~ geforce\ gtx\ (9|7|6|5|4) ]] || [[ "${lspci_out}" =~ quadro\ k ]]; then
    return 1
  fi

  return 0
}
