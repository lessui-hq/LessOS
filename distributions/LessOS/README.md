# LessOS

A minimal operating system distribution for running LessUI on handheld gaming devices.

LessOS is a fork of [ROCKNIX](https://github.com/ROCKNIX/distribution) stripped down to only the essential packages needed to boot and run the LessUI launcher. It trades ROCKNIX's comprehensive emulation support for a smaller, faster system designed specifically for LessUI.

## Architecture Overview

```
┌──────────────────────────────────────────────────────────┐
│                        Device                            │
├─────────────────────────────┬────────────────────────────┤
│      Partition 1 (FAT)      │    Partition 2 (exFAT)     │
│         System/Boot         │         Storage            │
├─────────────────────────────┼────────────────────────────┤
│  - Linux kernel             │  - lessos/init.sh          │
│  - System image (squashfs)  │  - LessUI binary & assets  │
│  - Device trees             │  - Roms/                   │
│                             │  - Saves/                  │
│                             │  - Bios/                   │
└─────────────────────────────┴────────────────────────────┘
```

### Key Differences from ROCKNIX

| Feature | ROCKNIX | LessOS |
|---------|---------|--------|
| Package count | ~410 | ~217 |
| Storage filesystem | ext4 | exFAT |
| Frontend | EmulationStation | LessUI |
| 32-bit support | Yes | No |
| Emulator packages | Built-in | None (handled by LessUI) |
| Window manager | Sway/Weston | None |

## Boot Flow

```
1. Device powers on
   │
2. lessos-boot.service starts (after storage mounted)
   │
3. First boot only: copy staged files from /usr/share/lessui → /storage
   │
4. Search for init.sh in priority order:
   │  ├─ /storage/games-external/lessos/init.sh  (SD2 - external card)
   │  ├─ /storage/games-internal/lessos/init.sh  (SD1 - internal)
   │  └─ /storage/lessos/init.sh                 (fallback)
   │
5. Execute init.sh → LessUI starts
```

### SD Card Priority

LessOS checks for `lessos/init.sh` in multiple locations, allowing you to:
- **Boot from external SD**: Place LessUI on a removable SD card for easy updates
- **Boot from internal storage**: Default fallback when no external card is present

## Directory Structure

### System Partition (read-only)
```
/usr/bin/lessos-boot       # Boot script that launches init.sh
/usr/share/lessui/         # Staged LessUI files (copied to storage on first boot)
```

### Storage Partition (exFAT, user-accessible)
```
/storage/
├── lessos/
│   └── init.sh            # Entry point script (launched by lessos-boot)
├── Roms/                  # Game files
├── Saves/                 # Save data
├── Bios/                  # BIOS files
└── .lessui-installed      # Marker file (indicates first-boot copy complete)
```

## Building LessOS

### Prerequisites

Same as ROCKNIX - Docker is recommended for a consistent build environment.

### Build Commands

```bash
# Build for RK3566 devices (RGB30, RK2023, etc.)
make LessOS-RK3566

# Build all LessOS targets
make LessOS-world
```

### Providing LessUI Files

The build will look for LessUI source files at `~/Code/LessUI-v0.2.0`. To customize:

1. Edit `projects/ROCKNIX/packages/lessui/package.mk`
2. Change the `LESSUI_SRC` variable to your LessUI location

If LessUI files are not found, a placeholder `init.sh` is created that displays a message asking the user to install LessUI manually.

## Packages

### lessos
`projects/ROCKNIX/packages/lessos/`

The boot system package containing:
- `lessos-boot` script that finds and executes init.sh
- `lessos-boot.service` systemd unit
- Profile script that sets `UI_SERVICE=lessos-boot.service`

### lessui
`projects/ROCKNIX/packages/lessui/`

Stages LessUI files during build:
- Copies LessUI files to `/usr/share/lessui/` in the system image
- Creates the `lessos/init.sh` entry point
- Files are copied to storage on first boot

## Configuration

Key settings in `distributions/LessOS/options`:

```bash
BASE_ONLY="true"           # Skip EmulationStation, themes, multimedia
EMULATION_DEVICE="no"      # LessUI handles emulation
ENABLE_32BIT="false"       # Not needed for LessUI
WINDOWMANAGER="none"       # LessUI runs directly on framebuffer/DRM
STORAGE_SIZE=4096          # 4GB exFAT partition (doesn't auto-resize)
```

## exFAT Storage Partition

LessOS uses exFAT instead of ext4 for the storage partition:

**Advantages:**
- Directly readable on Windows/macOS/Linux without special drivers
- Easy drag-and-drop file management
- No Linux filesystem permissions

**Considerations:**
- No auto-resize on first boot (fixed 4GB default)
- No filesystem-level permissions (everything is world-readable)

## Troubleshooting

### "No init.sh found" error

The boot script couldn't find `lessos/init.sh`. Ensure:
1. LessUI files are in `/storage/lessos/` on the device
2. The `init.sh` script exists and is executable
3. Check `/var/log/lessos-boot.log` for details

### First boot doesn't copy files

Check if `/storage/.lessui-installed` exists. If it does but files are missing:
```bash
rm /storage/.lessui-installed
reboot
```

## Development

### Logs
- Boot log: `/var/log/lessos-boot.log`
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
make LessOS-RK3566
```
