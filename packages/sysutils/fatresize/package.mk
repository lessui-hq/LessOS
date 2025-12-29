# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024 LessOS

PKG_NAME="fatresize"
PKG_VERSION="1.1.0"
PKG_SHA256="9232bc354b6c49a9e695e071bfd2d62ec79cdf4bc84928fcf1967fa39b75c33e"
PKG_LICENSE="GPL-3.0"
PKG_SITE="https://github.com/ya-mouse/fatresize"
PKG_URL="https://github.com/ya-mouse/fatresize/archive/refs/tags/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_INIT="parted:init util-linux:init"
PKG_LONGDESC="FAT16/FAT32 filesystem resizer"
PKG_TOOLCHAIN="autotools"

PKG_CONFIGURE_OPTS_INIT="--disable-shared"

makeinstall_init() {
  mkdir -p ${INSTALL}/usr/sbin
  cp ../.${TARGET_NAME}-init/fatresize ${INSTALL}/usr/sbin
}
