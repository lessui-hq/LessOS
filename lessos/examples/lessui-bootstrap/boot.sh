#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (C) 2024 LessUI (https://github.com/lessui-hq)

# LessUI Bootstrap for LessOS
#
# This script is called by LessOS and is responsible for:
#   - Mapping LessOS device info to LessUI platform names
#   - Setting up the LessUI environment
#   - Launching minui.elf
#
# LessOS provides these environment variables:
#   LESSOS_VERSION      - LessOS version
#   LESSOS_HW_DEVICE    - Hardware platform (H700, RK3566, RK3326, etc.)
#   LESSOS_HW_ARCH      - Architecture (aarch64, arm)
#   LESSOS_DEVICE_MODEL - Specific device model
#   LESSOS_STORAGE      - Storage partition path
#   LESSOS_EXTERNAL     - External SD path (if present)
#   LESSOS_BOOT_SOURCE  - Where we were loaded from (internal/external)
#
# This file should be placed at: .lessui/boot.sh on the SD card

#
# Map LessOS device to LessUI platform
#
get_platform() {
  # First try specific device model matching
  case "${LESSOS_DEVICE_MODEL}" in
    # SM8250 devices (Retroid Pocket series)
    *"Retroid Pocket 5"*|*"Retroid Pocket Flip2"*)
      echo "retroid5"; return ;;
    *"Retroid Pocket Mini"*)
      echo "retroidmini"; return ;;  # Covers Mini and Mini V2

    # H700 devices
    *"RG35XX Plus"*|*"RG35XX-PLUS"*|*"RG35XX H"*|*"RG35XX SP"*|*"RG35XXPLUS"*)
      echo "rg35xxplus"; return ;;
    *"RG28XX"*)
      echo "rg28xx"; return ;;
    *"RG40XX"*)
      echo "rg35xxplus"; return ;;  # Uses same platform
    *"RG34XX"*)
      echo "rg35xxplus"; return ;;  # Uses same platform

    # RK3566 devices
    *"RGB30"*)
      echo "rgb30"; return ;;
    *"RG353"*|*"RG503"*)
      echo "rgb30"; return ;;  # Compatible platform

    # RK3326 devices
    *"RG351M"*|*"RG351V"*|*"RG351MP"*|*"RG351P"*)
      echo "rg351m"; return ;;
    *"ODROID-GO2"*|*"ODROID-GO3"*)
      echo "rg351m"; return ;;  # Compatible platform
  esac

  # Fallback to platform-level matching
  case "${LESSOS_HW_DEVICE}" in
    SM8250) echo "retroid5" ;;   # Default SM8250 platform
    H700)   echo "rg35xxplus" ;;
    RK3566) echo "rgb30" ;;
    RK3326) echo "rg351m" ;;
    *)      echo "unknown" ;;
  esac
}

PLATFORM=$(get_platform)

# Determine root directory (where .lessui folder is)
if [ "${LESSOS_BOOT_SOURCE}" = "external" ]; then
  LESSUI_ROOT="${LESSOS_EXTERNAL}"
else
  LESSUI_ROOT="${LESSOS_STORAGE}"
fi

LESSUI_SYSTEM="${LESSUI_ROOT}/.system"
LESSUI_BIN="${LESSUI_SYSTEM}/${PLATFORM}/bin/minui.elf"

# Verify platform is supported
if [ "${PLATFORM}" = "unknown" ]; then
  echo "LessUI: Unknown device - ${LESSOS_DEVICE_MODEL} (${LESSOS_HW_DEVICE})"
  echo "LessUI: Please report this at https://github.com/lessui-hq/LessUI/issues"
  exit 1
fi

# Verify binary exists
if [ ! -x "${LESSUI_BIN}" ]; then
  echo "LessUI: Binary not found at ${LESSUI_BIN}"
  echo "LessUI: Platform=${PLATFORM}"
  echo "LessUI: Please ensure LessUI is properly extracted"
  exit 1
fi

# Set up environment
export HOME="${LESSUI_ROOT}"
export SDL_VIDEODRIVER="kmsdrm"
export SDL_AUDIODRIVER="alsa"
export LD_LIBRARY_PATH="${LESSUI_SYSTEM}/${PLATFORM}/lib:${LD_LIBRARY_PATH}"

# LessUI-specific environment
export LESSUI_PLATFORM="${PLATFORM}"
export LESSUI_ROOT="${LESSUI_ROOT}"
export LESSUI_SYSTEM="${LESSUI_SYSTEM}"

# Log startup
echo "LessUI: Platform=${PLATFORM}"
echo "LessUI: Root=${LESSUI_ROOT}"
echo "LessUI: Binary=${LESSUI_BIN}"

# Change to root directory and launch
cd "${LESSUI_ROOT}"
exec "${LESSUI_BIN}"
