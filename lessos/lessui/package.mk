# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024 LessUI (https://github.com/lessui-hq)

PKG_NAME="lessui"
PKG_VERSION="1.0.0"
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/lessui-hq/LessUI"
PKG_URL=""
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="LessOS bootstrap launcher - finds and runs a launcher from storage"
PKG_TOOLCHAIN="manual"

# LessUI is NOT built or installed by the build system.
# Instead, users extract the LessUI release package directly onto the
# storage partition, just like on other LessUI-supported platforms.
#
# The storage partition is mounted at /storage and the LessUI package
# should be extracted there, creating:
#   /storage/.system/<platform>/bin/minui.elf
#   /storage/.system/<platform>/lib/
#   /storage/.system/res/
#   /storage/.system/cores/
#   /storage/Roms/
#   /storage/Bios/
#
# This package only installs the boot script that looks for and launches
# LessUI from /storage/.system/

# Map ROCKNIX device names to LessUI platform names
get_lessui_platform() {
  case "${DEVICE}" in
    H700)
      echo "rg35xxplus"
      ;;
    RK3566)
      echo "rgb30"
      ;;
    RK3326)
      echo "rg351m"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

make_target() {
  : # No build step
}

makeinstall_target() {
  # Install startup script to /usr/bin
  mkdir -p ${INSTALL}/usr/bin
  cp ${PKG_DIR}/scripts/start_lessui.sh ${INSTALL}/usr/bin/
  chmod 755 ${INSTALL}/usr/bin/start_lessui.sh

  # Install systemd service
  mkdir -p ${INSTALL}/usr/lib/systemd/system
  cp ${PKG_DIR}/system.d/lessui.service ${INSTALL}/usr/lib/systemd/system/

  # Install autostart script (runs during boot to configure UI)
  mkdir -p ${INSTALL}/usr/lib/autostart/common
  cp ${PKG_DIR}/autostart/099-lessui ${INSTALL}/usr/lib/autostart/common/
  chmod 755 ${INSTALL}/usr/lib/autostart/common/099-lessui
}

post_install() {
  # Enable LessUI service
  enable_service lessui.service
}
