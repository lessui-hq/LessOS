# LessOS

A minimal Linux distribution for retro gaming handhelds. Designed to run LessUI, but supports any compatible launcher.

## Overview

LessOS is built on top of ROCKNIX, stripping out EmulationStation, RetroArch, and other heavy components to create a minimal OS. It uses a simple bootstrap protocol that allows any compatible launcher to run.

## Bootstrap Protocol

LessOS doesn't have any launcher baked in. Instead, it looks for a bootstrap script at boot:

```
/storage/games-external/.lessui/boot.sh   # External SD (checked first)
/storage/.lessui/boot.sh                  # Internal storage
```

The first executable `boot.sh` found is executed with these environment variables:

| Variable | Description | Example |
|----------|-------------|---------|
| `LESSOS_VERSION` | LessOS version | `1.0.0` |
| `LESSOS_HW_DEVICE` | Hardware platform | `H700`, `RK3566` |
| `LESSOS_HW_ARCH` | CPU architecture | `aarch64` |
| `LESSOS_DEVICE_MODEL` | Device model from DT | `Anbernic RG35XX Plus` |
| `LESSOS_STORAGE` | Storage mount point | `/storage` |
| `LESSOS_EXTERNAL` | External SD mount | `/storage/games-external` |
| `LESSOS_BOOT_SOURCE` | Where bootstrap found | `internal`, `external` |

The bootstrap script handles platform detection, environment setup, and launching the UI.

## Using with LessUI

1. Flash LessOS to your SD card
2. Extract LessUI package to the storage partition
3. Boot - LessOS finds `.lessui/boot.sh` and runs LessUI

LessUI releases for LessOS will include the `.lessui/boot.sh` bootstrap script.

## Core Principle: No Upstream Modifications

We do **not** modify ROCKNIX code directly. All LessOS customizations are:

1. **Additive** - New files alongside ROCKNIX
2. **Patches** - `.patch` files applied at build time
3. **Config overrides** - Using the build system's hierarchy

This ensures **effortless merges from upstream**.

## Project Structure

```
lessos/
├── distributions/LessOS/
│   └── options                    # Minimal distribution config
├── projects/ROCKNIX/packages/ui/lessui/
│   ├── package.mk
│   └── scripts/start_lessui.sh    # Bootstrap launcher
├── examples/lessui-bootstrap/
│   └── boot.sh                    # Example bootstrap for LessUI
├── patches/                       # Patches for upstream files
├── INVESTIGATION.md               # Detailed analysis
└── README-LessOS.md               # This file
```

## Target Devices

| ROCKNIX Device | Chip | Supported Handhelds |
|----------------|------|---------------------|
| **SM8250** | Snapdragon 865 | Retroid Pocket 5, Pocket Mini, Pocket Mini V2, Pocket Flip2 |
| H700 | Allwinner H700 | RG35XX Plus/H/Pro/SP, RG28XX, RG34XX, RG40XX |
| RK3566 | Rockchip RK3566 | RG353M/V/P, RG503, RGB30 |
| RK3326 | Rockchip RK3326 | RG351M/V/MP/P, RGB10/20S |

**Priority:** SM8250 (Retroid devices) is the first target for LessOS.

## Building

### Prerequisites

- **Linux host (amd64)** or Linux VM - macOS hosts have issues with the build system
- Docker or Podman
- ~50GB disk space
- ~16GB RAM recommended

### Known Issues

- The ROCKNIX Makefile passes host environment variables to Docker which breaks on macOS
- You'll need to either:
  1. Build on a Linux (amd64) host
  2. Use a Linux VM
  3. Apply the Makefile patches in `patches/` (breaks upstream compatibility)

### Quick Start

```bash
# Enter Docker build environment
make docker-shell

# Build LessOS for SM8250 (Retroid Pocket 5, Mini, etc.)
PROJECT=ROCKNIX DISTRO=LessOS DEVICE=SM8250 ARCH=aarch64 ./scripts/build_distro

# Output:
# release/LessOS-SM8250.aarch64-YYYYMMDD.img.gz
```

## Key Differences from ROCKNIX

| Feature | ROCKNIX | LessOS |
|---------|---------|--------|
| UI | EmulationStation | Any (via bootstrap) |
| Size | ~2-3GB | ~200-400MB |
| Storage partition | ext4 | exFAT |
| 32-bit support | Yes | No |
| Audio | PipeWire | ALSA only |
| Bluetooth | Yes | No (optional) |

## Storage Partition

LessOS uses **exFAT** for the storage partition:

- Windows/Mac can read/write directly (no special drivers)
- Same SD card structure works across devices
- Trade-off: No symlinks or Unix permissions

## For Launcher Developers

Want your launcher to work on LessOS? Just include a `.lessui/boot.sh` that:

1. Reads `LESSOS_*` environment variables
2. Maps the device to your platform names
3. Sets up your environment
4. Execs your launcher binary

See `examples/lessui-bootstrap/` for a reference implementation.

## Development Status

- [x] Investigation complete
- [x] Distribution config created
- [x] Bootstrap protocol defined
- [ ] Build tested
- [ ] H700 device tested
- [ ] Other devices tested

## Documentation

See [INVESTIGATION.md](./INVESTIGATION.md) for detailed analysis.

## License

ROCKNIX code is GPL-2.0. LessOS-specific additions are MIT licensed.
