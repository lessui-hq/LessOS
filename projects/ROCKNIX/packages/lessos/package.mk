# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024 LessOS

PKG_NAME="lessos"
PKG_VERSION="1.0.0"
PKG_LICENSE="GPL-2.0"
PKG_SITE="https://github.com/shauninman/LessOS"
PKG_URL=""
# Dependencies:
#   - SDL2, SDL2_image, SDL2_ttf, SDL2_mixer: Runtime libraries required by LessUI
#   - parted: Used by 050-lessos autostart to create partition 3
#   - p7zip: Provides 7za for extracting LessUI.zip
PKG_DEPENDS_TARGET="toolchain SDL2 SDL2_image SDL2_ttf SDL2_mixer parted p7zip"
PKG_LONGDESC="LessOS boot system - launches LessUI from lessos/init.sh"
PKG_TOOLCHAIN="manual"

makeinstall_target() {
  # Install boot scripts
  mkdir -p ${INSTALL}/usr/bin
  cp ${PKG_DIR}/sources/lessos-boot ${INSTALL}/usr/bin/
  cp ${PKG_DIR}/sources/lessos-automount ${INSTALL}/usr/bin/
  chmod 0755 ${INSTALL}/usr/bin/lessos-boot
  chmod 0755 ${INSTALL}/usr/bin/lessos-automount

  # Configure logind to ignore power/lid buttons (LessUI handles them)
  mkdir -p ${INSTALL}/usr/lib/systemd/logind.conf.d
  cp ${PKG_DIR}/config/logind-lessos.conf ${INSTALL}/usr/lib/systemd/logind.conf.d/

  # Note: autostart/, profile.d/, system.d/ subdirectories
  # are auto-installed by scripts/install
}

post_install() {
  # Enable LessOS services
  enable_service lessos-automount.service
  enable_service lessos-boot.service
}
