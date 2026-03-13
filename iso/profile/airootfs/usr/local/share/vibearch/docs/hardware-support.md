# Hardware Support

See also: [Docs Index](./README.md), [Architecture](./architecture.md), [Validation Matrix](./validation-matrix.md), [Troubleshooting Playbook](./troubleshooting-playbook.md)

## Firmware Support

- UEFI: supported
- Legacy BIOS: supported

## GPU Profiles

- AMD: Mesa + Vulkan Radeon path
- Intel: Mesa + Vulkan Intel path
- NVIDIA:
  - try `nvidia-open` first when hardware supports it
  - fallback to proprietary `nvidia` when open modules are a bad fit
- Hybrid (iGPU + NVIDIA): installs combined userspace stack + NVIDIA path

## Reality Check

- NVIDIA behavior can change with driver/kernel updates. Yes, it is annoying as hell.
- Hybrid laptops often need model-specific power tweaks.
- Validate in VM first, then test on physical hardware before trusting it with real work.
