# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2025 LessOS

PKG_NAME="lessos-splash"
PKG_VERSION="1.0.0"
PKG_LICENSE="GPL"
PKG_SITE=""
PKG_URL=""
PKG_DEPENDS_INIT="toolchain"
PKG_LONGDESC="LessOS splash screen application"
PKG_TOOLCHAIN="manual"

unpack() {
  mkdir -p ${PKG_BUILD}
  cp ${PKG_DIR}/*.c ${PKG_DIR}/*.h ${PKG_DIR}/Makefile ${PKG_BUILD}/
}

post_makeinstall_init() {
  mkdir -p ${INSTALL}/usr/share/lessos
  cp ${ROOT}/distributions/LessOS/lessos.png ${INSTALL}/usr/share/lessos/
}

make_init() {
  make CC="${CC}" \
       CFLAGS="${CFLAGS}" \
       LDFLAGS="${LDFLAGS}"
}

makeinstall_init() {
  mkdir -p ${INSTALL}/usr/bin
  cp lessos-splash ${INSTALL}/usr/bin/
}
