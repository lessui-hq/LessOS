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
- **Partition 2 (ext4)**: User storage (`/storage`) - fixed 512MB
- **Partition 3 (exFAT)**: LESSUI partition (`/storage/lessui`) - created on first boot, fills remaining space
- **External SD** (optional): Mounted at `/sd2` by `lessos-automount`

### Boot Flow
1. `lessos-automount.service` mounts external SD to `/sd2` (if present)
2. `050-lessos` (autostart) creates partition 3 if missing, mounts at `/storage/lessui`, extracts LessUI.zip
3. `lessos-boot.service` searches for init.sh: `/sd2/lessos/` → `/storage/lessui/lessos/`
4. Executes found `init.sh` → LessUI starts

### Key Directories
- `distributions/LessOS/` - Distribution config (options, version)
- `projects/ROCKNIX/packages/lessos/` - Boot system package
- `scripts/mkimage` - Image creation
- `scripts/get_env` - Docker environment variable whitelist

## LessOS-Specific Packages

### lessos
Boot system with two scripts:
- `lessos-automount` - mounts external SD card to `/sd2`
- `lessos-boot` - finds and executes `init.sh` from `/sd2/lessos/` or `/storage/lessui/lessos/`

Includes systemd services and profile override for `UI_SERVICE`.

## Key Configuration

In `distributions/LessOS/options`:
- `BASE_ONLY="true"` - Skip EmulationStation, themes, emulators
- `EMULATION_DEVICE="no"` - LessUI handles emulation
- `WINDOWMANAGER="none"` - Direct framebuffer/DRM
- `STORAGE_SIZE=512` - Fixed 512MB ext4 storage partition

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
/storage/lessui/lessos/init.sh
```
