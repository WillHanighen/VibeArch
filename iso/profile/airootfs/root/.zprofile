#!/usr/bin/env zsh

# Auto-launch Hyprland on the first virtual terminal in the live ISO.
if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" && "$(tty)" == "/dev/tty1" ]]; then
  if ! /usr/local/bin/vibearch-live-session; then
    echo "Live session failed. Falling back to root shell." >&2
    echo "See /tmp/vibearch-live-session.log (or /root/vibearch-live-session.log) for details." >&2
    exec /usr/bin/zsh -f
  fi
fi
