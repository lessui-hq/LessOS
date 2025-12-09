# LessOS Investigation Report

This document outlines how to build a minimal Linux distribution based on ROCKNIX that boots directly into LessUI.

## Executive Summary

ROCKNIX is a LibreELEC-derived embedded Linux distribution designed for retro gaming handhelds. It uses a sophisticated cross-compilation build system that supports 12+ device families. We can leverage this infrastructure to create **LessOS** - a minimal Linux that boots directly into LessUI instead of EmulationStation.

---

## Quick Reference - Key Decisions

| Topic | Decision |
|-------|----------|
| **Base** | ROCKNIX fork with no direct modifications |
| **Distribution** | New `distributions/LessOS/` (additive) |
| **Bootstrap Model** | LessOS looks for `.lessui/boot.sh`, launcher handles the rest |
| **Storage Filesystem** | exFAT (patch required) for easy Windows/Mac access |
| **Launcher Location** | User extracts launcher to storage partition |
| **Dual SD Cards** | External SD checked first - portable launcher SD works |
| **Environment** | LessOS exports `LESSOS_*` variables for launchers |
| **Customizations** | Additive files + patches (no upstream edits) |

## Files Created

```
lessos/
├── INVESTIGATION.md                    # This document
├── README-LessOS.md                    # Project overview
├── distributions/LessOS/
│   └── options                         # Minimal distribution config
├── projects/ROCKNIX/packages/ui/lessui/
│   ├── package.mk                      # Package definition
│   ├── scripts/start_lessui.sh         # LessOS bootstrap launcher
│   ├── system.d/lessui.service         # SystemD service
│   └── autostart/099-lessui            # Autostart hook
├── examples/
│   └── lessui-bootstrap/
│       ├── boot.sh                     # Example LessUI bootstrap for LessOS
│       └── README.md
└── patches/
    └── README.md                       # Patch documentation (patches TBD)
```

## Next Steps

1. **Test stock ROCKNIX build** - Build for SM8250 to verify environment works
2. **Create exFAT patches** - Modify `mkimage`, `fs-resize`, `init` for exFAT storage
3. **Build LessOS image** - `PROJECT=ROCKNIX DISTRO=LessOS DEVICE=SM8250 ARCH=aarch64 ./scripts/build_distro`
4. **Test on hardware** - Flash to Retroid Pocket 5/Mini, extract LessUI, boot
5. **Iterate** - Fix issues, add more devices

## First Target: SM8250 (Retroid Pocket Series)

The first devices to support are the modern Retroid handhelds:

| Device | Device Tree Model | LessUI Platform |
|--------|-------------------|-----------------|
| Retroid Pocket 5 | `Retroid Pocket 5` | `retroid5` |
| Retroid Pocket Mini | `Retroid Pocket Mini` | `retroidmini` |
| Retroid Pocket Mini V2 | `Retroid Pocket Mini V2` | `retroidmini` |
| Retroid Pocket Flip2 | `Retroid Pocket Flip2` | `retroid5` |

Note: The model string comes from `/sys/firmware/devicetree/base/model` and is set in the kernel DTS patches.

### SM8250 Device Info

- **Chip**: Qualcomm Snapdragon 865
- **CPU**: Cortex-A76 + Cortex-A55 (big.LITTLE)
- **GPU**: Adreno 650 (Freedreno driver)
- **Architecture**: aarch64
- **Features**: Vulkan support, touchscreen, fan control, LED control

### SM8250 Quirks from ROCKNIX

Platform quirks (`/usr/lib/autostart/quirks/platforms/SM8250/`):
- Touchscreen support
- Fan control
- LED control (analog stick LEDs)
- GPU overclock option
- Audio path configuration

Device-specific quirks:
- RP5/Flip2: GPU overclock enabled
- RP Mini/Mini V2: 4:3 aspect ratio, GPU overclock enabled

---

## LessUI Release Structure

Understanding how LessUI releases are structured helps clarify how LessOS will boot it.

### Release Package Layout

A LessUI release contains:

```
LessUI-YYYYMMDD-N/
├── LessUI.zip                    # Main package - user copies to SD card
├── README.txt                    # Installation instructions
├── Bios/                         # Sample BIOS folder structure
├── Roms/                         # Sample ROM folder structure
├── Saves/                        # Sample saves folder
├── Tools/                        # Utility tools
│
│ # Per-device bootstrap files (copied to TF1/NAND)
├── rg35xxplus/
│   └── dmenu.bin                 # Replaces stock launcher on TF1
├── rg35xx/
│   └── dmenu.bin                 # For original RG35XX
├── miyoo/                        # Miyoo Mini bootstrap
├── miyoo354/                     # Miyoo Mini Plus bootstrap
│   └── app/.tmp_update/          # Auto-update mechanism
├── miyoo355/                     # Miyoo Flip bootstrap
├── trimui/                       # Trimui Smart bootstrap
├── magicx/                       # MagicX bootstrap
└── em_ui.sh                      # M17 bootstrap
```

### LessUI.zip Contents

The main `LessUI.zip` that users extract to their SD card:

```
.system/
├── res/                          # Shared resources (fonts, images)
│   ├── InterTight-Bold.ttf       # UI font
│   ├── assets@1x.png             # UI sprites (multiple scales)
│   ├── bootlogo@*.bmp            # Boot images
│   └── ...
│
├── cores/                        # Shared libretro cores by architecture
│   ├── a53/                      # ARM64 (Cortex-A53 and similar)
│   │   ├── gambatte_libretro.so
│   │   ├── fceumm_libretro.so
│   │   └── ...
│   └── a7/                       # ARM32 (Cortex-A7 and similar)
│       ├── gambatte_libretro.so
│       └── ...
│
├── common/                       # Shared utilities
│   ├── bin/arm/                  # ARM32 binaries (jq, dufs, etc.)
│   ├── bin/arm64/                # ARM64 binaries
│   └── *.sh                      # Shared scripts
│
│ # Per-platform directories
├── rg35xxplus/
│   ├── bin/
│   │   ├── minui.elf             # Main launcher
│   │   ├── minarch.elf           # Libretro frontend
│   │   ├── keymon.elf            # Button monitor daemon
│   │   ├── show.elf              # Splash screen display
│   │   └── syncsettings.elf      # Settings sync
│   ├── lib/
│   │   ├── libSDL2-2.0.so.0      # Platform-specific SDL
│   │   ├── libmsettings.so       # Settings library
│   │   └── ...
│   ├── paks/                     # Emulator paks
│   │   └── Emus/
│   │       ├── GB.pak/
│   │       │   ├── launch.sh
│   │       │   └── default.cfg
│   │       ├── GBA.pak/
│   │       └── ...
│   ├── cores/                    # (empty - uses shared cores)
│   └── dat/
│       └── dmenu.bin             # Copy of bootstrap for TF1
│
├── rgb30/                        # RGB30 platform (uses SDL 1.2)
│   ├── bin/
│   ├── lib/
│   │   └── libSDL-1.2.so.0       # Different SDL version
│   ├── paks/
│   └── cores/
│
├── miyoomini/                    # Miyoo Mini platform
├── trimuismart/                  # Trimui Smart platform
├── m17/                          # M17 platform
└── ...
```

### Bootstrap Patterns

Different devices use different bootstrap mechanisms:

| Device Family | Bootstrap Method |
|---------------|------------------|
| RG35XX Plus/H/SP | `dmenu.bin` on TF1 boots LessUI from TF2 |
| Miyoo Mini/Plus | `app/.tmp_update/` auto-runs on boot |
| RGB30 | Moss firmware on TF1, LessUI on TF2 |
| Trimui | Similar to Miyoo - app folder override |

### How LessOS Changes This

With LessOS, the bootstrap is built into the OS:

**Traditional (stock OS + bootstrap):**
```
TF1: Stock OS + dmenu.bin (bootstrap)
TF2: LessUI.zip extracted → /.system/, /Roms/, etc.
```

**LessOS (single SD):**
```
SD Card:
├── Partition 1: Boot (FAT32) - kernel, DTB
├── Partition 2: System (SquashFS) - LessOS with start_lessui.sh
└── Partition 3: Storage (exFAT) - LessUI.zip extracted here
    ├── .system/rg35xxplus/bin/minui.elf  ← start_lessui.sh launches this
    ├── Roms/
    └── Bios/
```

**LessOS (dual SD):**
```
TF1 (Internal):
├── Partition 1: Boot (FAT32)
└── Partition 2: System (SquashFS) - LessOS

TF2 (External) - Standard LessUI SD:
└── Partition 1: (exFAT)
    ├── .system/rg35xxplus/bin/minui.elf  ← start_lessui.sh finds this
    ├── Roms/
    └── Bios/
```

The beauty: **The same LessUI SD card works in both setups** - whether as the storage partition of a single-SD LessOS install, or as an external SD in a dual-SD setup.

---

## LessOS Bootstrap Protocol

LessOS is designed as a **generic minimal Linux** that can run any compatible launcher. It doesn't have LessUI-specific code baked in. Instead, it uses a simple bootstrap protocol.

### How It Works

1. LessOS boots and runs its launcher service
2. The service looks for a bootstrap script at well-known locations
3. If found, it sets up environment variables and executes the bootstrap
4. The bootstrap script (provided by the launcher) handles everything else

### Bootstrap Locations

LessOS checks these paths in order:

```
/storage/games-external/.lessui/boot.sh   # External SD (checked first)
/storage/.lessui/boot.sh                  # Internal storage
```

The first executable `boot.sh` found is executed.

### Environment Variables

LessOS exports these `LESSOS_*` variables for the bootstrap to use:

| Variable | Description | Example |
|----------|-------------|---------|
| `LESSOS_VERSION` | LessOS version string | `1.0.0` |
| `LESSOS_HW_DEVICE` | Hardware platform (chip family) | `H700`, `RK3566`, `RK3326` |
| `LESSOS_HW_ARCH` | CPU architecture | `aarch64`, `arm` |
| `LESSOS_DEVICE_MODEL` | Specific device from device tree | `Anbernic RG35XX Plus` |
| `LESSOS_STORAGE` | Internal storage mount point | `/storage` |
| `LESSOS_EXTERNAL` | External SD mount point | `/storage/games-external` |
| `LESSOS_BOOT_SOURCE` | Where bootstrap was found | `internal`, `external` |

Additionally, all ROCKNIX device variables are available (`DEVICE_HAS_HDMI`, `DEVICE_ASPECT_RATIO`, etc.).

### Bootstrap Responsibilities

The bootstrap script is responsible for:

1. **Platform mapping** - Convert `LESSOS_HW_DEVICE` / `LESSOS_DEVICE_MODEL` to launcher-specific platform names
2. **Environment setup** - Set `LD_LIBRARY_PATH`, `SDL_VIDEODRIVER`, etc.
3. **Launching the UI** - `exec` the launcher binary

### Example: LessUI Bootstrap

LessUI would include a `.lessui/boot.sh` in its release package:

```bash
#!/bin/sh
# Map LessOS device to LessUI platform
case "${LESSOS_HW_DEVICE}" in
  H700)   PLATFORM="rg35xxplus" ;;
  RK3566) PLATFORM="rgb30" ;;
  RK3326) PLATFORM="rg351m" ;;
  *)      PLATFORM="unknown" ;;
esac

# Determine root based on where we booted from
if [ "${LESSOS_BOOT_SOURCE}" = "external" ]; then
  ROOT="${LESSOS_EXTERNAL}"
else
  ROOT="${LESSOS_STORAGE}"
fi

# Set up environment and launch
export LD_LIBRARY_PATH="${ROOT}/.system/${PLATFORM}/lib"
export SDL_VIDEODRIVER="kmsdrm"
cd "${ROOT}"
exec "${ROOT}/.system/${PLATFORM}/bin/minui.elf"
```

### Benefits of This Approach

1. **Separation of concerns** - LessOS doesn't need to know about LessUI internals
2. **Other launchers** - Any launcher can work with LessOS by providing a `boot.sh`
3. **Independent updates** - LessUI can update platform detection without LessOS changes
4. **Portable SD cards** - Same launcher SD works across LessOS devices
5. **Simple contract** - Just one file at one location with documented env vars

### SD Card Structure for LessUI on LessOS

```
/storage/                        # or /storage/games-external/
├── .lessui/
│   └── boot.sh                  # Bootstrap script (from LessUI package)
├── .system/
│   ├── rg35xxplus/
│   │   ├── bin/minui.elf
│   │   └── lib/
│   ├── rgb30/
│   ├── cores/
│   └── res/
├── Roms/
├── Bios/
└── Saves/
```

---

## Core Principle: No Upstream Modifications

**Critical**: We do not modify any ROCKNIX code directly. All LessOS customizations must be:

1. **Additive** - New files that sit alongside ROCKNIX code
2. **Patches** - `.patch` files applied at build time
3. **Overrides** - Using the build system's configuration hierarchy

This ensures effortless merges from upstream ROCKNIX. When ROCKNIX updates, we simply pull their changes and our customizations layer on top.

## ROCKNIX Build System Overview

### Architecture

```
ROCKNIX Build System
├── Makefile              # Top-level targets (make RK3566, make H700, etc.)
├── scripts/
│   ├── build_distro      # Main orchestration script
│   ├── build             # Recursive package builder
│   ├── image             # Image finalization
│   └── mkimage           # Disk image creation
├── config/
│   ├── options           # Global build settings
│   └── functions         # Build helper functions (1890 lines)
├── distributions/
│   └── ROCKNIX/options   # Feature flags (217 lines)
├── projects/
│   └── ROCKNIX/
│       ├── options       # Project defaults
│       ├── config.xml    # Device definitions
│       └── devices/      # Per-device configs
└── packages/             # 960 packages organized by category
```

### Key Concepts

1. **Configuration Hierarchy** (in order of precedence):
   - Global: `config/options`
   - Distribution: `distributions/ROCKNIX/options`
   - Project: `projects/ROCKNIX/options`
   - Device: `projects/ROCKNIX/devices/{DEVICE}/options`
   - User: `~/.rocknix/options`

2. **Build Flow**:
   ```
   make DEVICE → scripts/build_distro → scripts/build (recursive) → scripts/image → output.img.gz
   ```

3. **Package System**:
   - Each package has a `package.mk` defining: name, version, dependencies, build instructions
   - Virtual packages (meta-packages) define what goes into the final image

## LessUI Requirements

Based on analysis of the LessUI codebase, the minimal OS needs:

### Core Requirements

| Component | ROCKNIX Package | Notes |
|-----------|-----------------|-------|
| Linux Kernel | `linux` | Device-specific configs already exist |
| SDL 1.2 or 2.0 | `SDL`, `SDL2` | Graphics and input |
| SDL_image | `SDL_image`, `SDL2_image` | PNG/JPG loading |
| SDL_ttf | `SDL_ttf`, `SDL2_ttf` | Font rendering |
| zlib | `zlib` | ZIP file support |
| ALSA | `alsa-lib`, `alsa-utils` | Audio |
| libc/libm | `glibc` or `musl` | C library |
| pthread | included in libc | Threading |

### File System

| Mount Point | Type | Purpose |
|-------------|------|---------|
| `/` | SquashFS | Read-only system partition |
| `/storage` | ext4/FAT32 | User data, ROMs, saves |

### Device Interfaces

- `/dev/input/event*` - Button input
- `/dev/fb0` or DRM - Display
- ALSA devices - Audio
- sysfs/I2C - Battery, brightness, power management

## Recommended Approach

### Option 1: Create a LessOS Distribution (Recommended)

Create a new distribution alongside ROCKNIX that shares the same build infrastructure but produces a minimal image.

**Structure:**
```
distributions/
├── ROCKNIX/           # Existing
└── LessOS/
    └── options        # Minimal feature set
```

**Advantages:**
- Leverages existing device support and kernel configs
- Can share toolchains and package builds
- Easy to update from upstream ROCKNIX
- Clean separation of concerns

### Option 2: Create LessOS Devices

Create device variants under the existing ROCKNIX project:

```
projects/ROCKNIX/devices/
├── RK3566/            # Existing (full ROCKNIX)
├── RK3566-LessOS/     # Minimal variant
├── H700/              # Existing
└── H700-LessOS/       # Minimal variant
```

### Option 3: Feature Flags Only

Use user options to disable features:
```bash
# ~/.rocknix/options
ENABLE_32BIT="false"
EMULATION_DEVICE="no"
# ... etc
```

**Not recommended** - doesn't replace EmulationStation with LessUI

---

## Implementation Plan

### Phase 1: Create LessOS Distribution

1. **Create distribution directory**:
   ```bash
   mkdir -p distributions/LessOS
   ```

2. **Create minimal options file** (`distributions/LessOS/options`):
   ```bash
   # LessOS - Minimal Linux for LessUI
   DISTRONAME="LessOS"

   # Inherit base from ROCKNIX but override
   . distributions/ROCKNIX/options

   # Disable ROCKNIX-specific features
   EMULATION_DEVICE="no"           # No EmulationStation
   ENABLE_32BIT="false"            # No 32-bit support (saves ~500MB)
   PIPEWIRE_SUPPORT="no"           # Use ALSA only
   WIREGUARD_SUPPORT="no"          # No VPN
   ZEROTIER_SUPPORT="no"
   BLUETOOTH_SUPPORT="no"          # Can re-enable if needed
   SAMBA_SERVER="no"
   SFTP_SERVER="no"
   DEBUG_PACKAGES="no"

   # Keep essentials
   MODULES_PKG="yes"
   SWAP_SUPPORT="yes"
   ```

### Phase 2: Create LessUI Package

Create a new package that installs LessUI:

```
packages/lessui/
├── package.mk
├── sources/
│   └── lessui.tar.gz (or git clone)
└── scripts/
    └── lessui-autostart
```

**package.mk**:
```makefile
PKG_NAME="lessui"
PKG_VERSION="1.0.0"
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/lessui-hq/LessUI"
PKG_URL=""
PKG_DEPENDS_TARGET="SDL2 SDL2_image SDL2_ttf zlib"
PKG_LONGDESC="LessUI - Minimal libretro frontend"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp -r ${PKG_BUILD}/build/SYSTEM/${DEVICE}/* ${INSTALL}/

  # Install autostart
  mkdir -p ${INSTALL}/usr/lib/autostart
  cp ${PKG_DIR}/scripts/lessui-autostart ${INSTALL}/usr/lib/autostart/099-lessui
}
```

### Phase 3: Replace EmulationStation

The ROCKNIX boot process uses autostart scripts in:
```
projects/ROCKNIX/packages/rocknix/autostart/
```

For LessOS, we need to:

1. **Skip EmulationStation launch** (script `010-uimode`)
2. **Add LessUI launch script** (e.g., `099-lessui`)

**LessUI Autostart Script**:
```bash
#!/bin/bash
# /usr/lib/autostart/099-lessui

# Set up environment
export SDL_VIDEODRIVER=kmsdrm
export LD_LIBRARY_PATH=/storage/.system/lib:$LD_LIBRARY_PATH

# Launch LessUI
exec /storage/.system/bin/minui.elf
```

### Phase 4: Handle Device Specifics

Each target device needs:

1. **Kernel config** - Usually can reuse ROCKNIX configs
2. **Platform abstraction** - LessUI's `platform.h` and `platform.c`
3. **Device drivers** - Display, input, audio, battery

**Device Mapping (ROCKNIX → LessUI platform)**:

| ROCKNIX Device | Chip | LessUI Platform |
|----------------|------|-----------------|
| H700 | Allwinner H700 | rg35xx (plus/pro/h/sp) |
| RK3326 | Rockchip RK3326 | rg351m, rg351v, etc. |
| RK3566 | Rockchip RK3566 | rg353, rg503, etc. |

### Phase 5: Build Integration

**Option A: External LessUI Build**

Build LessUI separately using its Docker toolchains, then package the binaries:

```bash
# Build LessUI for the platform
cd ~/Code/LessUI
make build PLATFORM=rg35xxplus

# Package for LessOS
tar -czf lessui-rg35xxplus.tar.gz -C build/SYSTEM/rg35xxplus .
```

**Option B: Integrated Build**

Build LessUI as part of the ROCKNIX build system:

```makefile
# packages/lessui/package.mk
PKG_URL="https://github.com/lessui-hq/LessUI.git"
PKG_GIT_CLONE_BRANCH="main"

make_target() {
  # Use ROCKNIX's cross-compiler
  make PLATFORM=${DEVICE} CC=${CC} CXX=${CXX}
}
```

---

## Minimal Package List for LessOS

Based on ROCKNIX's package structure, here's what LessOS needs:

### Essential (Must Have)

```
# Core system
busybox              # Basic utilities
systemd              # Init system
udev                 # Device management
linux                # Kernel
linux-firmware       # Device firmware

# C library
glibc                # Or musl for smaller size

# Graphics
SDL2                 # Graphics/input
SDL2_image           # Image loading
SDL2_ttf             # Font rendering
libdrm               # Display
mesa                 # GPU driver (if needed)

# Audio
alsa-lib             # Audio library
alsa-utils           # Audio utilities

# Storage
util-linux           # Mount, etc.
e2fsprogs            # ext4 tools
dosfstools           # FAT32 tools

# Compression
zlib                 # ZIP support

# LessUI
lessui               # Our package
libretro-cores       # Emulator cores (separate package)
```

### Optional (Nice to Have)

```
# Networking (for updates, file transfer)
wpa_supplicant       # WiFi
openssh              # Remote access

# Bluetooth (for controllers)
bluez                # Bluetooth stack

# Debugging
dropbear             # Lightweight SSH
```

### What to Remove (vs Full ROCKNIX)

```
# EmulationStation and related
emulationstation     # ES-DE frontend
es-theme-*           # ES themes
rocknix-hotkey       # ROCKNIX controls
portmaster           # Port manager

# 32-bit support
lib32                # 32-bit libraries
box86                # x86 emulation

# Heavy features
pipewire             # Audio server (use ALSA)
samba                # File sharing
moonlight            # Game streaming
mangohud             # Overlay

# Per-system emulators (replaced by libretro cores)
retroarch            # Standalone RetroArch
dolphin              # Standalone emulators
pcsx2
aethersx2
etc.
```

---

## Estimated Image Sizes

| Configuration | Approximate Size |
|---------------|------------------|
| Full ROCKNIX | ~2-3 GB |
| LessOS (minimal) | ~200-400 MB |
| LessOS + all libretro cores | ~500-800 MB |

---

## Directory Structure for LessOS Development

```
lessos/
├── INVESTIGATION.md          # This document
├── README.md                  # Project overview
├── distributions/
│   └── LessOS/
│       └── options           # Distribution config
├── packages/
│   └── lessui/
│       ├── package.mk        # LessUI build recipe
│       └── scripts/          # Autostart, etc.
├── patches/                  # Any ROCKNIX patches needed
│   └── rocknix/
│       └── *.patch
└── docs/
    ├── building.md           # Build instructions
    └── devices/              # Per-device notes
```

---

## Next Steps

1. **Set up build environment**
   - Install Docker
   - Clone ROCKNIX repo (done - this is the fork)
   - Test building stock ROCKNIX for one device

2. **Create LessOS distribution**
   - Create `distributions/LessOS/options`
   - Test minimal build

3. **Create LessUI package**
   - Package LessUI binaries
   - Create autostart script

4. **Test on real hardware**
   - Start with one device (e.g., RG35XX Plus - H700)
   - Debug boot issues
   - Verify all hardware works

5. **Iterate and expand**
   - Add more device support
   - Optimize for size
   - Add update mechanism

---

## Key Files to Study

| File | Purpose |
|------|---------|
| `Makefile` | Build targets |
| `scripts/build_distro` | Main build script |
| `distributions/ROCKNIX/options` | Feature flags reference |
| `projects/ROCKNIX/devices/H700/options` | Device config example |
| `packages/virtual/image/package.mk` | What goes in final image |
| `projects/ROCKNIX/packages/rocknix/package.mk` | ROCKNIX meta-package |

---

## ROCKNIX Boot Flow (Detailed)

Understanding how ROCKNIX boots helps us know where to hook in LessUI:

```
1. Bootloader (U-Boot)
   └── Loads kernel + DTB from boot partition

2. Kernel
   └── Mounts SquashFS root filesystem
   └── Starts systemd

3. systemd
   └── Starts rocknix.target (default target)
   └── Starts rocknix-autostart.service

4. rocknix-autostart.service
   └── Runs /usr/bin/autostart script

5. autostart script (/usr/bin/autostart)
   └── Runs quirks from /usr/lib/autostart/quirks/
   └── Starts rocknix-automount service
   └── Runs scripts from /usr/lib/autostart/common/
       ├── 001-setup (cache, logs)
       ├── 003-upgrade (check updates)
       ├── 006-display (display init)
       ├── 007-rootpw (root password)
       ├── 008-perfmode (CPU governor)
       ├── 009-sleepmode (sleep config)
       ├── 010-uimode (UI selection - KEY FILE)
       ├── 050-audio (audio setup)
       └── 099-networkservices (WiFi, etc.)
   └── Sources /etc/profile for UI_SERVICE
   └── Starts ${UI_SERVICE} (emustation.service or sway.service)

6. UI Service (emustation.service)
   └── Runs /usr/bin/start_es.sh
   └── Launches EmulationStation
```

**Key insight**: The `010-uimode` script sets up `weston.startup` to point to `/usr/bin/start_es.sh`. For LessOS, we need to either:
- Replace this with a LessUI startup script, OR
- Create a completely separate systemd service for LessUI

---

## ROCKNIX Device Support

Devices currently supported by ROCKNIX that overlap with LessUI needs:

| ROCKNIX Device | Chip | Devices | LessUI Platform Equivalent |
|----------------|------|---------|---------------------------|
| H700 | Allwinner H700 | RG35XX Plus/H/Pro/SP, RG28XX, RG34XX, RG40XX, RGCubeXX | rg35xxplus |
| RK3326 | Rockchip RK3326 | RG351M/V/MP/P, ODROID-GO2/3, RGB10/20S | rg351m (partial) |
| RK3566 | Rockchip RK3566 | RG353M/V/P/VS/PS, RG503, RK2023, RGB30 | rgb30 |
| RK3588 | Rockchip RK3588 | GameForce Ace, RetroLite CM5 | - |
| S922X | Amlogic S922X | ODROID-GO Ultra, RGB10 Max 3 Pro | - |

**Priority for LessOS**: H700 (already have LessUI support, most popular devices)

---

## Practical Example: Building for H700

Here's a concrete example of what it would take to build LessOS for H700:

### Step 1: Create Distribution

```bash
# distributions/LessOS/options
```

### Step 2: Modify Makefile

Add LessOS targets:
```makefile
# Add to Makefile
LessOS-H700:
	PROJECT=ROCKNIX DISTRO=LessOS DEVICE=H700 ARCH=aarch64 ./scripts/build_distro
```

### Step 3: Build Command

```bash
# Using Docker
make docker-shell
PROJECT=ROCKNIX DISTRO=LessOS DEVICE=H700 ARCH=aarch64 ./scripts/build_distro

# Or native (requires all build deps)
make LessOS-H700
```

### Step 4: Output

```
release/LessOS-H700.aarch64-YYYYMMDD.img.gz
```

---

## Questions to Resolve

1. **Which devices to target first?**
   - H700 (RG35XX series) - already well-supported in LessUI
   - RK3566 (RG353, etc.) - popular devices

2. **SDL1 or SDL2?**
   - LessUI supports both
   - ROCKNIX uses SDL2 primarily
   - Recommend SDL2 for consistency

3. **Build LessUI inside or outside ROCKNIX?**
   - Outside (current approach) is simpler
   - Inside allows using ROCKNIX's toolchains directly

4. **How to handle libretro cores?**
   - LessUI already downloads pre-built cores
   - Could build them as part of ROCKNIX (more work, more control)
   - Recommend: continue using pre-built cores initially

5. **Update mechanism?**
   - ROCKNIX has OTA updates
   - Could leverage same system
   - Or simpler: manual SD card update (MinUI style)

---

## Appendix: Key ROCKNIX Variables

Variables you'll see in the build system:

| Variable | Example | Description |
|----------|---------|-------------|
| `PROJECT` | `ROCKNIX` | Project name (always ROCKNIX for us) |
| `DISTRO` | `ROCKNIX`, `LessOS` | Distribution to build |
| `DEVICE` | `H700`, `RK3566` | Target device/chip |
| `ARCH` | `aarch64`, `arm` | Target architecture |
| `DISPLAYSERVER` | `wl`, `no` | Wayland or none |
| `WINDOWMANAGER` | `swaywm-env`, `none` | Window manager |
| `MEDIACENTER` | `emulationstation`, `no` | UI application |
| `EMULATION_DEVICE` | `yes`, `no` | Include emulators |

---

## Appendix: File Locations Reference

| What | Where |
|------|-------|
| Kernel configs | `projects/ROCKNIX/devices/{DEVICE}/linux/linux.aarch64.conf` |
| Device options | `projects/ROCKNIX/devices/{DEVICE}/options` |
| Device patches | `projects/ROCKNIX/devices/{DEVICE}/patches/` |
| U-Boot config | `projects/ROCKNIX/devices/{DEVICE}/packages/u-boot/` |
| Autostart scripts | `projects/ROCKNIX/packages/rocknix/autostart/` |
| SystemD services | `projects/ROCKNIX/packages/rocknix/system.d/` |
| EmulationStation | `projects/ROCKNIX/packages/ui/emulationstation/` |
| Virtual packages | `packages/virtual/` |

---

## Appendix: exFAT Storage Partition

### Goal

Make the storage partition exFAT instead of ext4 so users can easily access files from Windows/Mac without special drivers.

### Current ROCKNIX Approach

- Storage partition is **ext4**
- Created in `scripts/mkimage` with `mke2fs -t ext4`
- Resized on first boot using `resize2fs` (triggered by `.please_resize_me` marker)
- Mounted at `/storage`

### exFAT Tradeoffs

| ext4 | exFAT |
|------|-------|
| Symlinks supported | No symlinks |
| Unix permissions | No Unix permissions |
| Journaling (crash-safe) | No journaling |
| Requires drivers on Windows | Native Windows/Mac support |
| Auto-resize on first boot | Different resize approach needed |

### Implementation Approach

Since we cannot modify `scripts/mkimage` directly, we have options:

**Option A: Patch file**
```
lessos/patches/scripts/mkimage-exfat.patch
```
Applied at build time to replace ext4 with exFAT creation.

**Option B: Post-build image modification**
A script that takes the built image and reformats the storage partition.

**Option C: Override script**
If the build system supports script overrides (needs investigation).

### Files That Need Patching

| File | Change |
|------|--------|
| `scripts/mkimage` | Replace `mke2fs` with `mkfs.exfat`, update parted type |
| `projects/ROCKNIX/packages/sysutils/busybox/scripts/fs-resize` | Replace `resize2fs` with exFAT resize or skip |
| `projects/ROCKNIX/packages/sysutils/busybox/scripts/init` | Update mount options for exFAT |

### LessUI Compatibility

Need to verify LessUI doesn't require symlinks at runtime on the storage partition. Build-time symlinks in the source are fine - only runtime symlinks on `/storage` matter.

Key paths to check:
- `/storage/.system/` - LessUI binaries and resources
- `/storage/Roms/` - Game files
- `/storage/Bios/` - BIOS files
- `/storage/.userdata/` - Settings and saves

### Reference: Knulli Approach

Knulli (Batocera-based) uses exFAT for their share partition successfully. They either:
1. Avoid symlinks in user-facing paths
2. Use a small ext4 partition for system config that needs symlinks

---

## Appendix: Dual SD Card Support

### How ROCKNIX Handles Two SD Cards

Many devices have two SD card slots:
- **Internal** - Usually where the OS lives (boot + system + storage partitions)
- **External** - Second slot for additional storage

ROCKNIX's `automount` script handles this with a clever approach:

### Mount Points

```
/storage/                    # Main storage partition (internal SD, partition 2)
├── games-internal/          # Bind mount or symlink to internal games
├── games-external/          # External SD card mounted here
└── roms/                    # Unified view (overlay or bind mount)
```

### Detection Logic

1. On boot, `automount` script runs
2. Scans for block devices: `mmcblk[0-9]`, `sd[a-z]`, `nvme[0-9]n[0-9]`
3. Looks for partitions with ext4/btrfs/fat/ntfs
4. Ignores partitions < 8GB (probably boot partitions)
5. Ignores devices with `boot0` (probably Android devices)
6. Mounts first suitable external device to `/storage/games-external`

### Merged Storage (OverlayFS)

If enabled and both cards support it (ext4/btrfs), ROCKNIX uses OverlayFS:

```bash
mount overlay -t overlay \
  -o lowerdir=/storage/games-external/roms,upperdir=/storage/games-internal/roms,workdir=... \
  /storage/roms
```

This merges both cards into a unified `/storage/roms` view. New files go to the "upper" card.

**Note**: OverlayFS requires ext4/btrfs. FAT/exFAT/NTFS can only be bind-mounted, not merged.

### LessOS Approach for Dual SD Cards

For LessOS, this is actually simpler and matches standard LessUI behavior:

**Single SD Card (OS + Storage)**
```
SD Card 1 (Internal):
├── Partition 1: Boot (FAT32) - kernel, dtb, bootloader
├── Partition 2: System (SquashFS) - read-only OS
└── Partition 3: Storage (exFAT) - LessUI + ROMs
    ├── .system/
    ├── Roms/
    └── Bios/
```

**Dual SD Card (OS separate from Storage)**
```
SD Card 1 (Internal):
├── Partition 1: Boot (FAT32)
└── Partition 2: System (SquashFS)

SD Card 2 (External) - Standard LessUI SD:
└── Partition 1: Storage (exFAT)
    ├── .system/
    ├── Roms/
    └── Bios/
```

### Why This is a UX Win

The dual SD card case is **exactly like a standard LessUI install**:
- User has their LessUI SD card with ROMs
- They just put it in the external slot
- OS boots from internal, games from external
- Same SD card works across devices (just like MinUI/LessUI today)

### Implementation for LessOS

The `start_lessui.sh` script needs to look for LessUI in multiple locations:

```bash
# Priority order:
# 1. External SD card (if present) - /storage/games-external/.system/
# 2. Internal storage - /storage/.system/

if [ -d "/storage/games-external/.system" ]; then
  LESSUI_SYSTEM="/storage/games-external/.system"
else
  LESSUI_SYSTEM="/storage/.system"
fi
```

This means:
- **Single SD**: LessUI on storage partition works
- **Dual SD**: LessUI on external SD works (feels like standard LessUI)
- **Portable SD**: Same LessUI SD card works in external slot of any LessOS device

---

## Appendix: Device Detection at Runtime

### How ROCKNIX Identifies Devices

ROCKNIX uses two levels of device identification:

**1. `HW_DEVICE`** - Build-time platform identifier (e.g., "H700", "RK3566")
- Set at **build time** in `scripts/image`
- Written to `/etc/os-release`
- Identifies the chip/platform family
- Used for platform-level quirks

**2. `QUIRK_DEVICE`** - Runtime device model (e.g., "Anbernic RG35XX Plus")
- Detected at **runtime** from device tree or DMI
- Read from `/sys/firmware/devicetree/base/model` (ARM) or `/sys/class/dmi/id/` (x86)
- Identifies the specific device model
- Used for device-specific quirks

### Where These Are Set

**`/etc/os-release`** (build-time):
```bash
OS_NAME="ROCKNIX"
OS_VERSION="..."
HW_DEVICE="H700"        # Set at build time from DEVICE variable
HW_ARCH="aarch64"
HW_CPU="Allwinner H700"
```

**`/etc/profile.d/002-autostart`** (runtime):
```bash
# ARM devices - read from device tree
if [ -e "/sys/firmware/devicetree/base/model" ]; then
  export QUIRK_DEVICE="$(strings /sys/firmware/devicetree/base/model)"
# x86 devices - read from DMI
else
  export QUIRK_DEVICE="$(strings /sys/class/dmi/id/sys_vendor) $(strings /sys/class/dmi/id/product_name)"
fi
```

### Quirks System

ROCKNIX has a sophisticated quirks system for device-specific behavior:

```
/usr/lib/autostart/quirks/
├── platforms/                    # Platform-level (HW_DEVICE)
│   ├── H700/
│   │   ├── bin/ledcontrol
│   │   ├── bin/gpu_overclock
│   │   └── 400-set_gpu_overclock
│   └── RK3566/
│       └── ...
└── devices/                      # Device-level (QUIRK_DEVICE)
    ├── Anbernic RG35XX Plus/
    │   └── 001-device_config
    ├── Anbernic RG351M/
    │   ├── 001-device_config
    │   └── 075-dpad-volbright
    └── ...
```

**Device config scripts** (`001-device_config`) write device-specific variables:
```bash
# /usr/lib/autostart/quirks/devices/Anbernic RG351M/001-device_config
cat <<EOF >/storage/.config/profile.d/001-device_config
DEVICE_PLAYBACK_PATH_SPK="HP"
DEVICE_PLAYBACK_PATH_HP="SPK"
DEVICE_VOLUME="100"
DEVICE_BATTERY_LED_STATUS="true"
DEVICE_PWR_LED_GPIO="77"
DEVICE_TEMP_SENSOR="/sys/devices/virtual/thermal/thermal_zone0/temp"
EOF
```

### Available Device Variables

From `999-export`, these variables are exported and available:

| Variable | Description |
|----------|-------------|
| `HW_DEVICE` | Platform/chip family (H700, RK3566, etc.) |
| `QUIRK_DEVICE` | Specific device model name |
| `DEVICE_HAS_FAN` | Device has cooling fan |
| `DEVICE_HAS_HDMI` | Device has HDMI output |
| `DEVICE_HAS_TOUCHSCREEN` | Device has touchscreen |
| `DEVICE_HAS_DUAL_SCREEN` | Device has two screens |
| `DEVICE_BATTERY_LED_STATUS` | Has battery LED indicator |
| `DEVICE_TEMP_SENSOR` | Path to temperature sensor |
| `DEVICE_VOLUME` | Default volume level |
| `DEVICE_ASPECT_RATIO` | Screen aspect ratio |
| `DEVICE_KEY_VOLUMEUP` | Key code for volume up |
| `DEVICE_KEY_VOLUMEDOWN` | Key code for volume down |
| ... and many more |

### How LessUI Can Use This

LessUI can read device info from multiple sources:

**Option A: Read `/etc/os-release`**
```bash
. /etc/os-release
echo "Platform: ${HW_DEVICE}"    # H700, RK3566, etc.
echo "Arch: ${HW_ARCH}"          # aarch64, arm
```

**Option B: Read Device Tree directly**
```bash
DEVICE_MODEL=$(strings /sys/firmware/devicetree/base/model)
# Returns: "Anbernic RG35XX Plus" or similar
```

**Option C: Use ROCKNIX's exported variables**
```bash
. /etc/profile
echo "Platform: ${HW_DEVICE}"
echo "Device: ${QUIRK_DEVICE}"
echo "Has HDMI: ${DEVICE_HAS_HDMI}"
```

### LessUI Platform Mapping

LessUI needs to map ROCKNIX identifiers to LessUI platform names:

```bash
# In start_lessui.sh
get_lessui_platform() {
  # Can use HW_DEVICE (build-time) or QUIRK_DEVICE (runtime)
  case "${HW_DEVICE}" in
    H700)     echo "rg35xxplus" ;;
    RK3566)   echo "rgb30" ;;
    RK3326)   echo "rg351m" ;;
    *)        echo "unknown" ;;
  esac
}
```

Or for more specific mapping:
```bash
get_lessui_platform() {
  case "${QUIRK_DEVICE}" in
    *"RG35XX Plus"*|*"RG35XX H"*|*"RG35XX SP"*)
      echo "rg35xxplus" ;;
    *"RGB30"*|*"RG353"*|*"RG503"*)
      echo "rgb30" ;;
    *"RG351"*)
      echo "rg351m" ;;
    *)
      # Fallback to HW_DEVICE
      case "${HW_DEVICE}" in
        H700)   echo "rg35xxplus" ;;
        RK3566) echo "rgb30" ;;
        RK3326) echo "rg351m" ;;
        *)      echo "unknown" ;;
      esac
      ;;
  esac
}
```

### Device Features for LessUI

LessUI can check ROCKNIX's device variables for hardware features:

```bash
# Check for HDMI support
if [ "${DEVICE_HAS_HDMI}" = "true" ]; then
  # Enable HDMI output option in settings
fi

# Check for analog sticks
if [ -n "${DEVICE_ANALOG_STICKS_LED_CONTROL}" ]; then
  # Device has analog sticks with LEDs
fi

# Get screen info
# (May need to read from other sources like DRM)
```

### Summary

For LessUI on LessOS:

1. **Platform detection** - Use `HW_DEVICE` from `/etc/os-release` (reliable, set at build time)
2. **Device model** - Use `QUIRK_DEVICE` from `/sys/firmware/devicetree/base/model` (runtime)
3. **Features** - Can leverage ROCKNIX's `DEVICE_*` variables or detect directly
4. **Quirks** - Can use ROCKNIX's quirk system or implement LessUI-specific quirks

---

## Appendix: Customization Strategy

### What We Add (New Files)

These are purely additive and don't touch ROCKNIX:

```
distributions/LessOS/
└── options                    # Our distribution config

projects/ROCKNIX/packages/ui/lessui/
├── package.mk                 # LessUI package definition
├── scripts/start_lessui.sh    # Boot script
├── system.d/lessui.service    # SystemD service
└── autostart/099-lessui       # Autostart hook
```

### What We Patch

These require `.patch` files in `lessos/patches/`:

```
lessos/patches/
├── scripts/
│   └── mkimage-exfat.patch    # exFAT storage partition
├── projects/ROCKNIX/packages/sysutils/busybox/
│   ├── fs-resize-exfat.patch  # exFAT resize handling
│   └── init-exfat.patch       # exFAT mount options
└── ...
```

### What We Override via Config

Using the configuration hierarchy (user options override distribution options):

```bash
# distributions/LessOS/options

# Disable features via standard config variables
EMULATION_DEVICE="no"
MEDIACENTER="no"
ENABLE_32BIT="false"
# etc.
```

### Build Process

```bash
# 1. Start with clean ROCKNIX
git checkout main
git pull upstream main

# 2. Apply LessOS patches
for patch in lessos/patches/**/*.patch; do
  git apply "$patch"
done

# 3. Build with LessOS distribution
PROJECT=ROCKNIX DISTRO=LessOS DEVICE=H700 ARCH=aarch64 ./scripts/build_distro
```

Or automate with a build script:
```bash
#!/bin/bash
# lessos/build.sh
./lessos/apply-patches.sh
PROJECT=ROCKNIX DISTRO=LessOS DEVICE=$1 ARCH=aarch64 ./scripts/build_distro
```
