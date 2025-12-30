# LessOS

A minimal operating system distribution for running LessUI on handheld gaming devices.

LessOS is a fork of [ROCKNIX](https://github.com/ROCKNIX/distribution) stripped down to only the essential packages needed to boot and run the LessUI launcher. It trades ROCKNIX's comprehensive emulation support for a smaller, faster system designed specifically for LessUI.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                   Device                                     │
├─────────────────────────┬──────────────────────┬────────────────────────────┤
│   Partition 1 (FAT32)   │  Partition 2 (ext4)  │    Partition 3 (exFAT)     │
│       System/Boot       │  Storage (/storage)  │  LESSUI (/storage/lessui)  │
├─────────────────────────┼──────────────────────┼────────────────────────────┤
│  - Linux kernel         │  - Config files      │  - LessUI binary & assets  │
│  - System image         │  - LessUI.zip        │  - Roms/                   │
│  - Device trees         │  - lessos/init.sh    │  - Saves/                  │
│                         │                      │  - Bios/                   │
└─────────────────────────┴──────────────────────┴────────────────────────────┘
                    Optional: External SD mounted at /sd2
```

### Key Differences from ROCKNIX

| Feature | ROCKNIX | LessOS |
|---------|---------|--------|
| Package count | ~410 | ~217 |
| Storage filesystem | ext4 | ext4 + exFAT (LESSUI) |
| Frontend | EmulationStation | LessUI |
| 32-bit support | Yes | No |
| Emulator packages | Built-in | None (handled by LessUI) |
| Window manager | Sway/Weston | None |

## Boot Flow

```
1. Device powers on
   │
2. First boot: fs-resize expands partition 2, reboots
   │
3. lessos-automount.service mounts external SD to /sd2 (if present)
   │
4. lessos-boot.service creates partition 3 if missing, mounts at /storage/lessui
   │  └─ If /storage/LessUI.zip exists, extracts it to /storage/lessui
   │
5. lessos-boot.service searches for init.sh:
   │  ├─ /sd2/lessos/init.sh  (external SD card)
   │  └─ /storage/lessos/init.sh   (internal storage)
   │
6. Execute init.sh → LessUI starts
```

### SD Card Priority

LessOS checks for `lessos/init.sh` in multiple locations, allowing you to:
- **Boot from external SD**: Place LessUI on a removable SD card at `/sd2/lessos/`
- **Boot from internal storage**: Default fallback at `/storage/lessos/`

## Directory Structure

### System Partition (read-only)
```
/usr/bin/lessos-automount  # Mounts external SD to /sd2
/usr/bin/lessos-boot       # Boot script that launches init.sh
```

### Storage Partition (ext4, 512MB)
```
/storage/
├── lessos/
│   └── init.sh            # Entry point script (launched by lessos-boot)
└── LessUI.zip             # Extracted to LESSUI partition on first boot
```

### LESSUI Partition (exFAT, fills remaining space)
```
/storage/lessui/
├── LessUI                 # LessUI binary
├── assets/                # LessUI assets
├── Roms/                  # Game files
├── Saves/                 # Save data
└── Bios/                  # BIOS files
```

### External SD (optional, mounted at /sd2)
```
/sd2/
├── lessos/
│   └── init.sh            # Alternative boot location (takes priority)
├── Roms/                  # Game files
├── Saves/                 # Save data
└── Bios/                  # BIOS files
```

## Building LessOS

### Prerequisites

Same as ROCKNIX - Docker is recommended for a consistent build environment.

### Build Commands

```bash
# Build for RK3566 devices (RGB30, RK2023, etc.)
make docker-LessOS-RK3566

# Build all LessOS targets
make LessOS-world
```

## Packages

### lessos
`projects/ROCKNIX/packages/lessos/`

The boot system package containing:
- `lessos-automount` script that mounts external SD to `/sd2`
- `lessos-boot` script that finds and executes init.sh
- Systemd services for both scripts
- Profile script that sets `UI_SERVICE=lessos-boot.service`

## Configuration

Key settings in `distributions/LessOS/options`:

```bash
BASE_ONLY="true"           # Skip EmulationStation, themes, multimedia
EMULATION_DEVICE="no"      # LessUI handles emulation
ENABLE_32BIT="false"       # Not needed for LessUI
WINDOWMANAGER="none"       # LessUI runs directly on framebuffer/DRM
STORAGE_SIZE=512           # Fixed 512MB ext4 storage partition
```

## Partition Layout

LessOS uses a three-partition layout:

1. **System (FAT32)**: Read-only boot partition with kernel and system image
2. **Storage (ext4, 512MB)**: Config files, LessUI.zip, and init.sh
3. **LESSUI (exFAT)**: Created on first boot, fills remaining space

The exFAT LESSUI partition provides:
- Cross-platform compatibility (readable on Windows/macOS/Linux)
- No 4GB file size limit (unlike FAT32)
- Storage for games, saves, and BIOS files

## Troubleshooting

### "No init.sh found" error

The boot script couldn't find `lessos/init.sh`. Ensure:
1. LessUI files are in `/storage/lessos/` or `/sd2/lessos/` on the device
2. The `init.sh` script exists and is executable
3. Check `/var/log/lessos-boot.log` for details

### External SD not mounting

Check the automount log:
```bash
cat /var/log/lessos-automount.log
```

## Development

### Logs
- Boot log: `/var/log/lessos-boot.log`
- Automount log: `/var/log/lessos-automount.log`
- System journal: `journalctl -u lessos-boot.service`

### Testing init.sh manually
```bash
systemctl stop lessos-boot
/storage/lessos/init.sh
```

### Rebuilding after changes
```bash
# Clean the lessos package and rebuild
DISTRO=LessOS PROJECT=ROCKNIX DEVICE=RK3566 ARCH=aarch64 ./scripts/clean lessos
make docker-LessOS-RK3566
```
