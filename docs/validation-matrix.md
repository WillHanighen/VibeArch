# Validation Matrix

See also: [Docs Index](./README.md), [Architecture](./architecture.md), [Hardware Support](./hardware-support.md), [Troubleshooting Playbook](./troubleshooting-playbook.md)

Run this before claiming the build is “stable.” If half this list is unchecked, you are shipping vibes, not engineering.

## Firmware Coverage

- [ ] UEFI install in QEMU/OVMF
- [ ] BIOS install in QEMU/SeaBIOS

## GPU Coverage

- [ ] AMD/Intel baseline path in VM
- [ ] NVIDIA path on real hardware or passthrough VM
- [ ] hybrid laptop sanity run

## Functional Checks

- [ ] reaches display/session target on first boot
- [ ] Hyprland launches with expected defaults
- [ ] Waybar, terminal, launcher, browser work
- [ ] NetworkManager connects over Ethernet and Wi-Fi
- [ ] PipeWire audio path works
- [ ] `bash /usr/local/share/vibearch/scripts/validate-install.sh` passes
- [ ] rerunning postinstall is idempotent (no config chaos)

## Pass Criteria

MVP is “good enough to ship” when:

- firmware checks pass
- every GPU class has at least one passing run
- no blocking installer regressions remain

Anything less is a test build. Treat it like one.

If someone asks “did you validate this?”, this checklist is your receipt.
