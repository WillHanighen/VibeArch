#!/usr/bin/env bash

set -euo pipefail

: "${TARGET_ROOT:=/mnt}"

chroot_exec() {
  arch-chroot "${TARGET_ROOT}" /bin/bash -lc "$*"
}

chroot_write_file() {
  local target_file="$1"
  local content="$2"
  arch-chroot "${TARGET_ROOT}" /bin/bash -lc "cat > '${target_file}' <<'EOF'
${content}
EOF"
}
