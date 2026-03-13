# Architecture

See also: [Docs Index](./README.md), [Hardware Support](./hardware-support.md), [Validation Matrix](./validation-matrix.md), [Troubleshooting Playbook](./troubleshooting-playbook.md)

## Why It Is Structured This Way

- installer logic is split so one bad step does not nuke the whole run
- builds are reproducible so “works on my machine” excuses can die in a fire
- hardware branching is explicit so debugging is not a psychic exercise

## Main Pieces

- `iso/build-iso.sh`
  - stages project assets into profile rootfs
  - runs `mkarchiso` using deterministic work/output paths
- `installer/main.sh`
  - collects inputs
  - detects firmware/GPU profile
  - executes step scripts in strict order
- `installer/lib/*.sh`
  - shared plumbing (UI, logging, hardware detection, state, chroot wrappers)
- `installer/steps/*.sh`
  - isolated phases (preflight, disking, base, bootloader, GPU, desktop, finalize)

## Runtime Flow

1. `main.sh` writes state to `/tmp/vibearch-installer/install.conf`.
2. Each step sources state + shared libs.
3. Step updates are persisted with `save_config_var`.
4. Logs go to `/tmp/vibearch-installer/install.log`.

## Non-Negotiable Installer Rules

- every script runs with `set -euo pipefail`
- fatal errors exit non-zero and leave logs behind
- disk destruction requires explicit confirmation
- bootloader path follows detected firmware mode
- GPU stack is chosen by detected profile + NVIDIA open/proprietary heuristic

If you violate these rules, enjoy your late-night recovery session and cold coffee.
