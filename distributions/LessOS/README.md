# LessOS

A minimal operating system distribution for running LessUI on handheld gaming devices.

LessOS is a fork of [ROCKNIX](https://github.com/ROCKNIX/distribution) stripped down to only the essential packages needed to boot and run the LessUI launcher. It trades ROCKNIX's comprehensive emulation support for a smaller, faster system designed specifically for LessUI.

## Architecture Overview

```
┌──────────────────────────────────────────────────────────┐
│                        Device                            │
├─────────────────────────────┬────────────────────────────┤
│      Partition 1 (FAT32)    │    Partition 2 (FAT32)     │
│         System/Boot         │     Storage (/storage)     │
├─────────────────────────────┼────────────────────────────┤
│  - Linux kernel             │  - lessos/init.sh          │
│  - System image (squashfs)  │  - LessUI binary & assets  │
│  - Device trees             │  - Roms/                   │
│                             │  - Saves/                  │
│                             │  - Bios/                   │
└─────────────────────────────┴────────────────────────────┘
          Optional: External SD mounted at /storage2
```

### Key Differences from ROCKNIX

| Feature | ROCKNIX | LessOS |
|---------|---------|--------|
| Package count | ~410 | ~217 |
| Storage filesystem | ext4 | FAT32 |
| Frontend | EmulationStation | LessUI |
| 32-bit support | Yes | No |
| Emulator packages | Built-in | None (handled by LessUI) |
| Window manager | Sway/Weston | None |

## Boot Flow

```
1. Device powers on
   │
2. First boot: fs-resize expands partition 2 to fill SD card, reboots
   │
3. lessos-automount.service mounts external SD to /storage2 (if present)
   │
4. lessos-boot.service searches for init.sh:
   │  ├─ /storage2/lessos/init.sh  (external SD card)
   │  └─ /storage/lessos/init.sh   (internal storage)
   │
5. Execute init.sh → LessUI starts
```

### SD Card Priority

LessOS checks for `lessos/init.sh` in multiple locations, allowing you to:
- **Boot from external SD**: Place LessUI on a removable SD card at `/storage2/lessos/`
- **Boot from internal storage**: Default fallback at `/storage/lessos/`

## Directory Structure

### System Partition (read-only)
```
/usr/bin/lessos-automount  # Mounts external SD to /storage2
/usr/bin/lessos-boot       # Boot script that launches init.sh
```

### Storage Partition (FAT32, user-accessible)
```
/storage/
└── lessos/
    └── init.sh            # Entry point script (launched by lessos-boot)
```

### External SD (optional, mounted at /storage2)
```
/storage2/
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
- `lessos-automount` script that mounts external SD to `/storage2`
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
STORAGE_SIZE=4096          # Initial 4GB FAT32 (auto-resized on first boot)
```

## FAT32 Storage Partition

LessOS uses FAT32 instead of ext4 for the storage partition:

**Advantages:**
- Directly readable on Windows/macOS/Linux without special drivers
- Easy drag-and-drop file management
- Auto-resizes to fill SD card on first boot

**Considerations:**
- No filesystem-level permissions (everything is world-readable)
- 4GB file size limit (FAT32 limitation)

## Troubleshooting

### "No init.sh found" error

The boot script couldn't find `lessos/init.sh`. Ensure:
1. LessUI files are in `/storage/lessos/` or `/storage2/lessos/` on the device
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
