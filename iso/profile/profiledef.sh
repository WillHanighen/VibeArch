#!/usr/bin/env bash

iso_name="vibearch"
iso_label="VIBEARCH_$(date +%Y%m)"
iso_publisher="VibeArch <https://example.com>"
iso_application="VibeArch Hyprland Live ISO"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
buildmodes=("iso")
bootmodes=(
  "bios.syslinux"
  "uefi.systemd-boot"
)
pacman_conf="pacman.conf"
airootfs_image_type="erofs"
airootfs_image_tool_options=("-zlzma,109" "-E" "ztailpacking")
bootstrap_tarball_compression=("zstd" "-c" "-T0" "--long")
file_permissions=(
  ["/usr/local/bin/vibearch-installer"]="0:0:755"
  ["/usr/local/bin/vibearch-live-session"]="0:0:755"
  ["/usr/local/bin/fastfetch"]="0:0:755"
  ["/root/customize_airootfs.sh"]="0:0:755"
)
