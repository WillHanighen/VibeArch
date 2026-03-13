#!/usr/bin/env bash

set -euo pipefail

target_user="$(id -un)"
if [[ "${1:-}" == "--user" && -n "${2:-}" ]]; then
  target_user="${2}"
fi

if ! id -u "${target_user}" >/dev/null 2>&1; then
  echo "Unknown user: ${target_user}" >&2
  exit 1
fi

target_home="$(getent passwd "${target_user}" | cut -d: -f6)"
if [[ -z "${target_home}" ]]; then
  echo "Could not resolve home for user: ${target_user}" >&2
  exit 1
fi

zsh_bin="/usr/bin/zsh"
if [[ ! -x "${zsh_bin}" ]]; then
  echo "zsh is not installed; skipping zsh defaults." >&2
  exit 0
fi

if [[ "$(id -u)" -eq 0 ]]; then
  usermod -s "${zsh_bin}" "${target_user}" >/dev/null 2>&1 || true
fi

omz_dir="${target_home}/.oh-my-zsh"
if [[ ! -d "${omz_dir}" ]] && command -v git >/dev/null 2>&1; then
  if command -v timeout >/dev/null 2>&1; then
    timeout 20 git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "${omz_dir}" >/dev/null 2>&1 || true
  else
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "${omz_dir}" >/dev/null 2>&1 || true
  fi
fi

zshrc_file="${target_home}/.zshrc"
if [[ ! -f "${zshrc_file}" ]] || grep -q "vibearch-managed-zsh" "${zshrc_file}" >/dev/null 2>&1; then
  if [[ -d "${omz_dir}" ]]; then
    cat >"${zshrc_file}" <<EOF
# vibearch-managed-zsh
export ZSH="${omz_dir}"
ZSH_THEME="robbyrussell"
plugins=(git sudo)
source "\$ZSH/oh-my-zsh.sh"

alias ll="ls -alF"
alias la="ls -A"
alias l="ls -CF"
EOF
  else
    cat >"${zshrc_file}" <<'EOF'
# vibearch-managed-zsh
autoload -Uz compinit
compinit

setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY

alias ll="ls -alF"
alias la="ls -A"
alias l="ls -CF"
EOF
  fi
fi

if [[ "$(id -u)" -eq 0 ]]; then
  chown -R "${target_user}:${target_user}" "${target_home}/.zshrc" "${target_home}/.oh-my-zsh" 2>/dev/null || true
fi
