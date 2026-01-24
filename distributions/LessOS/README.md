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
│  - Linux kernel         │  - Config files      │  - lessos/init.sh          │
│  - System image         │  - LessUI.zip *      │  - LessUI binary & assets  │
│  - Device trees         │                      │  - Roms/                   │
│                         │                      │  - Saves/                  │
│                         │                      │  - Bios/                   │
└─────────────────────────┴──────────────────────┴────────────────────────────┘
          * LessUI.zip is optional; extracted to partition 3 on first boot
                    Optional: External SD mounted at /sd2
```

### Key Differences from ROCKNIX

| Feature | ROCKNIX | LessOS |
|---------|---------|--------|
| Frontend | EmulationStation | LessUI |
| Emulators | Built-in | Handled by LessUI |
| Storage | ext4 | ext4 + exFAT (LESSUI) |

## Boot Flow

```
1. Device powers on
   │
2. lessos-automount.service mounts external SD to /sd2 (if present)
   │
3. 050-lessos (autostart) creates partition 3 if missing, mounts at /storage/lessui
   │  └─ If /storage/LessUI.zip exists, extracts it to /storage/lessui (optional)
   │
4. lessos-boot.service searches for init.sh:
   │  ├─ /sd2/lessos/init.sh  (external SD card - checked first)
   │  └─ /storage/lessui/lessos/init.sh   (LESSUI partition - fallback)
   │
5. Execute init.sh → LessUI starts
   │
   └─ If no init.sh found: displays error message and powers off after 5 seconds
```

**Note:** Partition 3 is always created regardless of whether LessUI.zip is included. The payload is optional.

### SD Card Priority

LessOS checks for `lessos/init.sh` in multiple locations, allowing you to:
- **Boot from external SD**: Place LessUI on a removable SD card at `/sd2/lessos/`
- **Boot from internal storage**: Default fallback at `/storage/lessui/lessos/`

### Environment Variables

The following environment variables are available to `init.sh`:

| Variable | Description | Example |
|----------|-------------|---------|
| `LESSOS_DEVICE` | Device model | `Anbernic RG353P` |
| `LESSOS_PLATFORM` | Device family/SoC | `RK3566` |
| `LESSOS_ARCH` | CPU architecture | `aarch64` |
| `LESSOS_VERSION` | OS version | `1.0` |
| `LESSOS_DIR` | Path to lessos directory | `/storage/lessui/lessos` |
| `LESSOS_STORAGE` | Storage root for Roms/Saves | `/storage/lessui` or `/sd2` |
| `DISPLAY_WIDTH` | Framebuffer width in pixels | `640` |
| `DISPLAY_HEIGHT` | Framebuffer height in pixels | `480` |
| `DISPLAY_ROTATION` | Framebuffer rotation (0-3) | `0` |

## Directory Structure

### System Partition (read-only)
```
/usr/bin/lessos-automount  # Mounts external SD to /sd2
/usr/bin/lessos-boot       # Boot script that launches init.sh
```

### Storage Partition (ext4, 512MB)
```
/storage/
└── LessUI.zip             # Optional: extracted to LESSUI partition on first boot
```

### LESSUI Partition (exFAT, fills remaining space)
```
/storage/lessui/
├── lessos/
│   └── init.sh            # Entry point script (launched by lessos-boot)
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

# Build for SM8250 devices
make docker-LessOS-SM8250

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
2. **Storage (ext4, 512MB)**: Config files and optional LessUI.zip
3. **LESSUI (exFAT)**: Created on first boot, fills remaining space

The exFAT LESSUI partition provides:
- Cross-platform compatibility (readable on Windows/macOS/Linux)
- No 4GB file size limit (unlike FAT32)
- Storage for games, saves, and BIOS files

## Troubleshooting

### "No init.sh found" error

The boot script couldn't find `lessos/init.sh`. Ensure:
1. LessUI files are in `/storage/lessui/lessos/` or `/sd2/lessos/` on the device
2. The `init.sh` script exists and is executable
3. Check `/var/log/lessos-boot.log` for details

### External SD not mounting

Check the automount log:
```bash
cat /var/log/lessos-automount.log
```

## Development

### Branching Strategy

LessOS is a fork of [ROCKNIX](https://github.com/ROCKNIX/distribution). We maintain two branches:

```
next     ← Synced with upstream ROCKNIX
  ↓
lessos   ← LessOS development (default branch)
```

- **`next`**: Tracks upstream ROCKNIX. Periodically synced with `ROCKNIX/distribution:next`.
- **`lessos`**: All LessOS-specific changes. This is the default branch.

### Syncing with Upstream

First-time setup (add ROCKNIX as upstream remote):

```bash
git remote add upstream https://github.com/ROCKNIX/distribution.git
```

When ROCKNIX makes a release or significant updates:

```bash
# Fetch upstream changes
git fetch upstream next
git checkout next
git merge upstream/next
git push origin next

# Merge into lessos
git checkout lessos
git merge next
# Resolve any conflicts, test, push
git push origin lessos
```

### Reviewing Fork Changes

To see what LessOS changes vs upstream ROCKNIX:

```bash
git log next..lessos --oneline     # Commits
git diff next..lessos --stat       # File summary
git diff next..lessos --name-only  # File list
```

### Releases

LessOS releases are aligned with ROCKNIX releases to benefit from their testing. We use date-based tags matching ROCKNIX's format:

```bash
# Tag a release (format: YYYYMMDD)
git checkout lessos
git tag -a 20250102 -m "LessOS 20250102"
git push origin 20250102
```

When to release:
- After merging a new ROCKNIX release into `lessos`
- After significant LessOS-specific fixes or features

### Version File

The `version` file controls the OS version shown in the system. Update `OS_VERSION` for major changes:

```bash
OS_VERSION="1.0"  # Increment for breaking changes
```

### Logs
- Boot log: `/var/log/lessos-boot.log`
- Automount log: `/var/log/lessos-automount.log`
- System journal: `journalctl -u lessos-boot.service`

### Testing init.sh manually
```bash
systemctl stop lessos-boot
/storage/lessui/lessos/init.sh
```

### Rebuilding after changes
```bash
# Clean the lessos package and rebuild
DISTRO=LessOS PROJECT=ROCKNIX DEVICE=RK3566 ARCH=aarch64 ./scripts/clean lessos
make docker-LessOS-RK3566
```
