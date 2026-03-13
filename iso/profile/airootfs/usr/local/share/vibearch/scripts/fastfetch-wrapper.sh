#!/usr/bin/env bash

set -euo pipefail

FASTFETCH_BIN="/usr/bin/fastfetch"
ASSET_BASE="/usr/local/share/vibearch/assets"
SVG_LOGO="${ASSET_BASE}/logo.svg"
TEXT_LOGO="${ASSET_BASE}/logo-fastfetch.txt"

if [[ ! -x "${FASTFETCH_BIN}" ]]; then
  echo "fastfetch is not installed at ${FASTFETCH_BIN}" >&2
  exit 127
fi

# Respect explicit logo arguments from the user.
for arg in "$@"; do
  case "${arg}" in
  --logo|-l|--file|--file-raw|--raw|--chafa|--kitty|--kitty-direct|--kitty-icat|--iterm|--sixel|--data|--data-raw)
    exec "${FASTFETCH_BIN}" "$@"
    ;;
  esac
done

# Prefer SVG rendering through chafa; fallback to ASCII text logo.
if [[ -f "${SVG_LOGO}" ]]; then
  if "${FASTFETCH_BIN}" --chafa "${SVG_LOGO}" "$@"; then
    exit 0
  fi
fi

if [[ -f "${TEXT_LOGO}" ]]; then
  exec "${FASTFETCH_BIN}" --file-raw "${TEXT_LOGO}" "$@"
fi

exec "${FASTFETCH_BIN}" "$@"
