#!/bin/bash
# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024 LessUI (https://github.com/lessui-hq)

# LessOS Bootstrap Launcher
#
# LessOS is a minimal Linux that looks for a launcher bootstrap script
# at a well-known location and executes it. This allows any compatible
# launcher to run on LessOS.
#
# Bootstrap locations (checked in order):
#   1. /storage/games-external/.lessui/boot.sh  (external SD)
#   2. /storage/.lessui/boot.sh                 (internal storage)
#
# The bootstrap script is responsible for:
#   - Platform/device detection
#   - Setting up its own environment
#   - Launching its UI
#
# LessOS provides these environment variables for use by the bootstrap:
#   LESSOS_VERSION      - LessOS version string
#   LESSOS_HW_DEVICE    - Hardware platform (H700, RK3566, RK3326, etc.)
#   LESSOS_HW_ARCH      - Architecture (aarch64, arm)
#   LESSOS_DEVICE_MODEL - Specific device model from device tree
#   LESSOS_STORAGE      - Path to storage partition (/storage)
#   LESSOS_EXTERNAL     - Path to external SD if present (/storage/games-external)
#   LESSOS_BOOT_SOURCE  - Where bootstrap was found (internal/external)
#
# ROCKNIX device variables are also available (DEVICE_HAS_HDMI, etc.)
# See /etc/profile for full list.

set -e

# Source system profile
. /etc/profile

#
# Set up LESSOS_* environment variables
#

# Version
export LESSOS_VERSION="${OS_VERSION:-unknown}"

# Hardware identifiers (from ROCKNIX)
export LESSOS_HW_DEVICE="${HW_DEVICE:-unknown}"
export LESSOS_HW_ARCH="${HW_ARCH:-$(uname -m)}"

# Device model from device tree (runtime detection)
if [ -e "/sys/firmware/devicetree/base/model" ]; then
  export LESSOS_DEVICE_MODEL="$(tr -d '\0' </sys/firmware/devicetree/base/model)"
else
  export LESSOS_DEVICE_MODEL="${QUIRK_DEVICE:-unknown}"
fi

# Storage paths
export LESSOS_STORAGE="/storage"
export LESSOS_EXTERNAL="/storage/games-external"

#
# Find and execute bootstrap
#

BOOTSTRAP_NAME=".lessui/boot.sh"
BOOTSTRAP=""

# Check external SD first (allows portable launcher SD cards)
if [ -d "${LESSOS_EXTERNAL}" ] && [ -x "${LESSOS_EXTERNAL}/${BOOTSTRAP_NAME}" ]; then
  BOOTSTRAP="${LESSOS_EXTERNAL}/${BOOTSTRAP_NAME}"
  export LESSOS_BOOT_SOURCE="external"
# Then check internal storage
elif [ -x "${LESSOS_STORAGE}/${BOOTSTRAP_NAME}" ]; then
  BOOTSTRAP="${LESSOS_STORAGE}/${BOOTSTRAP_NAME}"
  export LESSOS_BOOT_SOURCE="internal"
fi

# Log environment
echo "LessOS: Version=${LESSOS_VERSION}"
echo "LessOS: HW_DEVICE=${LESSOS_HW_DEVICE}"
echo "LessOS: HW_ARCH=${LESSOS_HW_ARCH}"
echo "LessOS: DEVICE_MODEL=${LESSOS_DEVICE_MODEL}"
echo "LessOS: BOOT_SOURCE=${LESSOS_BOOT_SOURCE:-none}"

# Execute bootstrap if found
if [ -n "${BOOTSTRAP}" ]; then
  echo "LessOS: Executing ${BOOTSTRAP}"
  exec "${BOOTSTRAP}"
fi

# No bootstrap found
echo ""
echo "=========================================="
echo "  No launcher found!"
echo "=========================================="
echo ""
echo "LessOS looks for a bootstrap script at:"
echo "  ${LESSOS_EXTERNAL}/${BOOTSTRAP_NAME}"
echo "  ${LESSOS_STORAGE}/${BOOTSTRAP_NAME}"
echo ""
echo "To install a launcher (e.g., LessUI):"
echo "  1. Extract the launcher package to your SD card"
echo "  2. Ensure ${BOOTSTRAP_NAME} exists and is executable"
echo "  3. Reboot"
echo ""
echo "Device: ${LESSOS_DEVICE_MODEL}"
echo "Platform: ${LESSOS_HW_DEVICE} (${LESSOS_HW_ARCH})"
echo ""
echo "Dropping to shell..."
echo ""
exec /bin/sh
