# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024 LessOS

PKG_NAME="lessui"
PKG_VERSION="0.2.0"
PKG_LICENSE="Proprietary"
PKG_SITE="https://github.com/shauninman/LessUI"
PKG_URL=""
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="LessUI frontend files for LessOS"
PKG_TOOLCHAIN="manual"

# Path to LessUI source - can be overridden
LESSUI_SRC="${HOME}/Code/LessUI-v0.2.0"

makeinstall_target() {
  # Stage LessUI files for copying to storage partition during image creation
  # These will be placed in /usr/share/lessui and copied to storage by mkimage

  LESSUI_STAGE="${INSTALL}/usr/share/lessui"
  mkdir -p "${LESSUI_STAGE}"

  if [ -d "${LESSUI_SRC}" ]; then
    echo "Staging LessUI files from ${LESSUI_SRC}..."

    # Copy common directories
    for dir in Bios Roms Saves Tools bin; do
      if [ -d "${LESSUI_SRC}/${dir}" ]; then
        cp -r "${LESSUI_SRC}/${dir}" "${LESSUI_STAGE}/"
      fi
    done

    # Copy README if it exists
    if [ -f "${LESSUI_SRC}/README.txt" ]; then
      cp "${LESSUI_SRC}/README.txt" "${LESSUI_STAGE}/"
    fi

    # Create the lessos directory with a placeholder init.sh
    # The actual init.sh will be added when LessUI binary for this platform is ready
    mkdir -p "${LESSUI_STAGE}/lessos"
    cat > "${LESSUI_STAGE}/lessos/init.sh" << 'INITEOF'
#!/bin/bash
# LessUI init script for LessOS
# This is a placeholder - replace with actual init.sh when platform binary is ready

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LESSUI_DIR="$(dirname "${SCRIPT_DIR}")"
cd "${LESSUI_DIR}"

echo "LessUI placeholder init.sh"
echo "Platform binary not yet available for this device."
echo ""
echo "LessUI directory: ${LESSUI_DIR}"
echo ""
echo "Waiting for LessUI binary..."

# Keep running so service doesn't restart
while true; do
  sleep 60
done
INITEOF
    chmod +x "${LESSUI_STAGE}/lessos/init.sh"

    echo "LessUI files staged to ${LESSUI_STAGE}"
  else
    echo "WARNING: LessUI source not found at ${LESSUI_SRC}"
    echo "Creating minimal structure..."

    # Create minimal structure with placeholder
    mkdir -p "${LESSUI_STAGE}/lessos"
    mkdir -p "${LESSUI_STAGE}/Roms"
    mkdir -p "${LESSUI_STAGE}/Saves"
    mkdir -p "${LESSUI_STAGE}/Bios"

    cat > "${LESSUI_STAGE}/lessos/init.sh" << 'INITEOF'
#!/bin/bash
# LessUI init script for LessOS
# LessUI files were not found during build - please install manually

echo "LessUI not installed during build."
echo "Please copy LessUI files to /storage/"
echo ""

while true; do
  sleep 60
done
INITEOF
    chmod +x "${LESSUI_STAGE}/lessos/init.sh"
  fi
}
