# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024 LessOS

PKG_NAME="lessos"
PKG_VERSION="1.0.0"
PKG_LICENSE="GPL-2.0"
PKG_SITE="https://github.com/shauninman/LessOS"
PKG_URL=""
PKG_DEPENDS_TARGET="toolchain SDL2 SDL2_image SDL2_ttf SDL2_mixer"
PKG_LONGDESC="LessOS boot system - launches LessUI from lessos/init.sh"
PKG_TOOLCHAIN="manual"

makeinstall_target() {
  # Install the boot script
  mkdir -p ${INSTALL}/usr/bin
  cp ${PKG_DIR}/sources/lessos-boot ${INSTALL}/usr/bin/
  chmod 0755 ${INSTALL}/usr/bin/lessos-boot
}

post_install() {
  # Enable the LessOS boot service
  enable_service lessos-boot.service
}
