# VibeArch

VibeArch is an Arch-based live ISO with a guided installer and Hyprland defaults.  
It exists to avoid “mystery distro bullshit” and keep the build/install flow explicit.

## What You Actually Get

- reproducible ISO builds via `mkarchiso`
- guided TUI installer with loud destructive confirmations
- ext4-first install flow with runtime swap options
- UEFI + BIOS support
- GPU-aware setup for AMD/Intel/NVIDIA/hybrid
- live ISO that jumps straight into Hyprland
- `hyprscrolling` setup through `hyprpm` on first session
- `fastfetch` preinstalled with VibeArch logos (`assets/logo.svg` + `assets/logo-fastfetch.txt`)

## Repo Map (So You Stop Guessing)

- `iso/` profile + build logic
- `installer/` controller, libs, ordered steps
- `config/` Hyprland, Waybar, Rofi defaults
- `scripts/` helper scripts (build, VM, validation, postinstall)
- `docs/` the docs you should read before breaking things

## Documentation

- [Docs Index](./docs/README.md)
- [Architecture](./docs/architecture.md)
- [Hardware Support](./docs/hardware-support.md)
- [Docker Build Workflow](./docs/docker-build.md)
- [Validation Matrix](./docs/validation-matrix.md)
- [Troubleshooting Playbook](./docs/troubleshooting-playbook.md)

## Build On Arch Host

1. Install deps: `archiso`, `rsync`, `squashfs-tools`, `git`.
2. Build:

```bash
bash iso/build-iso.sh
```

1. Artifact appears in `out/`.

## Build On Non-Arch Host (Docker)

If your host is Ubuntu/Fedora/Debian/etc, use Docker and skip dependency hell.

```bash
bash scripts/docker-build-iso.sh
```

Notes:

- uses `docker/Dockerfile.builder`
- runs `mkarchiso` in privileged container
- clean rebuild is default (`work/` reset) so stale artifacts do not screw you
- incremental mode for debugging:

```bash
VIBEARCH_CLEAN_BUILD=0 bash scripts/docker-build-iso.sh
```

- open builder shell:

```bash
bash scripts/docker-dev-shell.sh
```

## Boot In QEMU

Quick launch:

```bash
bash scripts/run-iso-qemu.sh
```

Useful variants:

- specific ISO: `bash scripts/run-iso-qemu.sh --iso out/vibearch-*.iso`
- BIOS mode: `BOOT_MODE=bios bash scripts/run-iso-qemu.sh`
- dry run: `bash scripts/run-iso-qemu.sh --dry-run`
- larger VM: `RAM_MB=8192 CPUS=6 DISK_GB=64 bash scripts/run-iso-qemu.sh`
- black-screen recovery:
  `QEMU_GL=off QEMU_VGA=std RESET_OVMF=1 DEBUG_SERIAL=1 bash scripts/run-iso-qemu.sh`

## Installer Usage

From live media:

```bash
vibearch-installer
```

It collects disk/user/swap info and executes steps in strict order.

## Hyprscrolling Defaults

`hyprscrolling` is auto-enabled with `hyprpm`.

Default binds:

- `SUPER + .` move view right by column
- `SUPER + ,` move view left by column
- `SUPER + SHIFT + .` move active window right column
- `SUPER + SHIFT + ,` move active window left column

## Validation

Inside installed system:

```bash
bash /usr/local/share/vibearch/scripts/validate-install.sh
```

## Fastfetch Defaults

`fastfetch` is installed by default on live and installed systems.

When you run `fastfetch`, VibeArch now does this:

- tries SVG logo via `assets/logo.svg` (chafa renderer)
- falls back to ASCII logo via `assets/logo-fastfetch.txt`

So yes, both assets are wired in.

## Contributing

Use this flow unless you enjoy self-inflicted chaos:

1. `bash scripts/docker-dev-shell.sh`
2. make changes
3. `bash scripts/docker-build-iso.sh`
4. `bash scripts/run-iso-qemu.sh`

If something broke, document what broke and how you fixed it.  
“works now lol” is not documentation.

## Safety

- installer wipes selected disk
- test in VM before touching real hardware
- this distro is under active development, so expect regressions
- do not daily-drive without backups unless you like losing weekends
