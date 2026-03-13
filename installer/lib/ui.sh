#!/usr/bin/env bash

set -euo pipefail

ui_has_whiptail() {
  command -v whiptail >/dev/null 2>&1
}

ui_input() {
  local prompt="$1"
  local default_value="${2:-}"
  local result=""

  if ui_has_whiptail; then
    result="$(whiptail --title "VibeArch Installer" --inputbox "${prompt}" 10 78 "${default_value}" 3>&1 1>&2 2>&3)"
  else
    printf "%s [%s]: " "${prompt}" "${default_value}"
    read -r result
    result="${result:-${default_value}}"
  fi

  echo "${result}"
}

ui_password() {
  local prompt="$1"
  local result=""

  if ui_has_whiptail; then
    result="$(whiptail --title "VibeArch Installer" --passwordbox "${prompt}" 10 78 3>&1 1>&2 2>&3)"
  else
    printf "%s: " "${prompt}"
    stty -echo
    read -r result
    stty echo
    printf "\n"
  fi

  echo "${result}"
}

ui_confirm() {
  local prompt="$1"

  if ui_has_whiptail; then
    whiptail --title "VibeArch Installer" --yesno "${prompt}" 10 78
    return $?
  fi

  local answer=""
  printf "%s [y/N]: " "${prompt}"
  read -r answer
  [[ "${answer}" =~ ^([yY][eE][sS]|[yY])$ ]]
}

ui_menu() {
  local title="$1"
  local prompt="$2"
  shift 2
  local options=("$@")
  local result=""
  local i

  if ui_has_whiptail; then
    local whiptail_args=()
    for i in "${options[@]}"; do
      local key="${i%%::*}"
      local label="${i#*::}"
      whiptail_args+=("${key}" "${label}")
    done
    result="$(whiptail --title "${title}" --menu "${prompt}" 20 78 10 "${whiptail_args[@]}" 3>&1 1>&2 2>&3)"
    echo "${result}"
    return 0
  fi

  echo "${title}"
  echo "${prompt}"
  local idx=1
  for i in "${options[@]}"; do
    local key="${i%%::*}"
    local label="${i#*::}"
    printf "  %d) %s - %s\n" "${idx}" "${key}" "${label}"
    idx=$((idx + 1))
  done

  local selection=""
  while true; do
    printf "Select option [1-%d]: " "${#options[@]}"
    read -r selection
    if [[ "${selection}" =~ ^[0-9]+$ ]] && ((selection >= 1 && selection <= ${#options[@]})); then
      echo "${options[$((selection - 1))]%%::*}"
      return 0
    fi
    echo "Invalid selection"
  done
}

ui_message() {
  local text="$1"
  if ui_has_whiptail; then
    whiptail --title "VibeArch Installer" --msgbox "${text}" 12 78
    return 0
  fi
  echo "${text}"
}
