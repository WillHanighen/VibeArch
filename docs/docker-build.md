# Docker Build Workflow

See also: [Docs Index](./README.md), [Architecture](./architecture.md), [Validation Matrix](./validation-matrix.md), [Troubleshooting Playbook](./troubleshooting-playbook.md)

If your host is not Arch, this is the sane path. You get reproducible builds without turning your host into a dependency landfill.

## Prerequisites

- Docker installed and usable
- optional: hardware virtualization support for QEMU tests

## Build ISO In Docker

```bash
bash scripts/docker-build-iso.sh
```

This script:

1. builds `docker/Dockerfile.builder` as `vibearch-builder:latest`
2. runs a privileged container with repo mounted at `/workspace`
3. executes `bash iso/build-iso.sh` inside container
4. writes artifacts to `out/` on your host

Default mode is clean rebuild (`work/` reset each run), because stale artifacts are a pain in the ass and waste hours.

For deliberate incremental debugging:

```bash
VIBEARCH_CLEAN_BUILD=0 bash scripts/docker-build-iso.sh
```

## Open Contributor Shell

```bash
bash scripts/docker-dev-shell.sh
```

That drops you into the same builder environment used by CI-style builds.

## Boot ISO In QEMU

```bash
bash scripts/run-iso-qemu.sh
```

Useful options:

- explicit ISO: `bash scripts/run-iso-qemu.sh --iso out/your.iso`
- BIOS mode: `BOOT_MODE=bios bash scripts/run-iso-qemu.sh`
- VM sizing: `RAM_MB=8192 CPUS=6 DISK_GB=64 bash scripts/run-iso-qemu.sh`
- dry-run: `bash scripts/run-iso-qemu.sh --dry-run`

## Troubleshooting

- `docker: permission denied`
  - add user to docker group or run with sudo
- `UEFI mode requested but OVMF firmware files were not found`
  - install host OVMF package (`ovmf` or `edk2-ovmf`)
  - Ubuntu often uses `OVMF_CODE_4M.fd` and `OVMF_VARS_4M.fd` (launcher auto-detects these)
- `KVM not available`
  - enable virtualization in firmware or run QEMU in software mode

If you skip these checks and then file “it black screens” with no logs, that is on you.
