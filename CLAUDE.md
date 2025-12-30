# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LessOS is a minimal Linux distribution for handheld gaming devices, forked from ROCKNIX. It's stripped down (~217 packages vs ~410) to run the LessUI launcher instead of EmulationStation.

## Build Commands

```bash
# Build LessOS for RK3566 devices (uses Docker)
make docker-LessOS-RK3566

# Build without Docker (requires full toolchain)
make LessOS-RK3566

# Clean a specific package and rebuild
DISTRO=LessOS PROJECT=ROCKNIX DEVICE=RK3566 ARCH=aarch64 ./scripts/clean lessos
make LessOS-RK3566

# Enter Docker shell for debugging
make docker-shell
```

## Architecture

### Partition Layout
- **Partition 1 (FAT32)**: Read-only system - kernel, squashfs system image, device trees
- **Partition 2 (FAT32)**: User storage (`/storage`) - empty on first boot, auto-expanded to fill SD card
- **External SD** (optional): Mounted at `/storage2` by `lessos-automount`

### Boot Flow
1. First boot: `fs-resize` expands partition 2 to fill SD card, reboots
2. `lessos-automount.service` mounts external SD to `/storage2` (if present)
3. `lessos-boot.service` searches for init.sh: `/storage2/lessos/` → `/storage/lessos/`
4. Executes found `init.sh` → LessUI starts

### Key Directories
- `distributions/LessOS/` - Distribution config (options, version)
- `projects/ROCKNIX/packages/lessos/` - Boot system package
- `scripts/mkimage` - Image creation (handles FAT32 for LessOS)
- `scripts/get_env` - Docker environment variable whitelist

## LessOS-Specific Packages

### lessos
Boot system with two scripts:
- `lessos-automount` - mounts external SD card to `/storage2`
- `lessos-boot` - finds and executes `init.sh` from `/storage2/lessos/` or `/storage/lessos/`

Includes systemd services and profile override for `UI_SERVICE`.

## Key Configuration

In `distributions/LessOS/options`:
- `BASE_ONLY="true"` - Skip EmulationStation, themes, emulators
- `EMULATION_DEVICE="no"` - LessUI handles emulation
- `WINDOWMANAGER="none"` - Direct framebuffer/DRM
- `STORAGE_SIZE=4096` - Initial 4GB FAT32 (auto-resized on first boot)

## On-Device Debugging

```bash
# Boot logs
cat /var/log/lessos-boot.log
cat /var/log/lessos-automount.log

# Service status
journalctl -u lessos-automount.service
journalctl -u lessos-boot.service

# Test init.sh manually
systemctl stop lessos-boot
/storage/lessos/init.sh

# Re-trigger partition resize (will reformat storage!)
touch /storage/.please_resize_me && reboot
```
