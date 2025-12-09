#!/bin/bash
# LessOS Build Script
#
# This script applies LessOS patches and builds for the specified device.
#
# Usage: ./build-lessos.sh <DEVICE>
# Example: ./build-lessos.sh SM8250

set -e

DEVICE="${1:-SM8250}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCHES_DIR="${SCRIPT_DIR}/patches"

echo "================================"
echo "LessOS Build Script"
echo "================================"
echo "Device: ${DEVICE}"
echo ""

# Apply patches
echo "Applying patches..."
for patch in $(find "${PATCHES_DIR}" -name "*.patch" -type f 2>/dev/null); do
  echo "  Applying: ${patch#${PATCHES_DIR}/}"
  git apply "${patch}" 2>/dev/null || {
    echo "    (already applied or failed)"
  }
done
echo ""

# Build
echo "Starting build..."
echo "PROJECT=ROCKNIX DISTRO=LessOS DEVICE=${DEVICE} ARCH=aarch64"
echo ""

PROJECT=ROCKNIX DISTRO=LessOS DEVICE="${DEVICE}" ARCH=aarch64 ./scripts/build_distro

echo ""
echo "================================"
echo "Build complete!"
echo "Output: release/LessOS-${DEVICE}.aarch64-*.img.gz"
echo "================================"
