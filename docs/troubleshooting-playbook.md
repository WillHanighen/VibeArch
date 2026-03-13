# Troubleshooting Playbook

See also: [Docs Index](./README.md), [Architecture](./architecture.md), [Hardware Support](./hardware-support.md), [Validation Matrix](./validation-matrix.md)

Use this when things break (they will). Fast diagnosis beats random config thrashing and panic edits.

## Installer Dies During Package Install

- confirm network from live ISO:
  - `ping -c1 archlinux.org`
- refresh mirror state if needed
- rerun installer and inspect:
  - `/tmp/vibearch-installer/install.log`

## System Boots To Console Instead Of Display Session

- chroot into target root and run:
  - `systemctl enable greetd`
  - `systemctl status greetd`
- validate `/etc/greetd/config.toml` syntax

## Black Screen On NVIDIA

- switch to TTY and inspect:
  - `/etc/modprobe.d/nvidia.conf`
  - `journalctl -b -p err`
- if `nvidia-open` is unstable on your hardware, move to proprietary `nvidia` packages

## No Audio

- verify packages exist: `pipewire`, `pipewire-pulse`, `wireplumber`
- check user services:
  - `systemctl --user status pipewire`
  - `systemctl --user status wireplumber`

## No Network Tray/Applet

- confirm `nm-applet` exists
- confirm `nm-applet` is launched in Hyprland `exec-once`
- verify `NetworkManager` service status

## Reapply Desktop Defaults (When Config Is Fucked)

```bash
bash /usr/local/share/vibearch/scripts/postinstall.sh
```

This re-syncs Hyprland/Waybar/Rofi defaults into user config paths.

If this does not fix it, gather logs first, then complain.
