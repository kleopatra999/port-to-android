#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error when substituting.
set -x # Print commands and their arguments as they are executed.
shopt -s extglob

HOST=arm-linux-androideabi
VERBOSE=${VERBOSE:-}
if test -n "$VERBOSE"
then
    SILENT_RULES="V=1" # verbose make output
    CONFIGURE_QUIET=
else
    SILENT_RULES="V=" # silent make output
    CONFIGURE_QUIET="--quiet"
fi

. pkgs.sh

VERSION="${VERSION:-10.3.1}"
BUILD="${BUILD:-linux-x86_64}"

PLATFORM="${PLATFORM:-android-21}"
ABI="${ABI:-armeabi}"
COMPILER="${COMPILER:-gnu-4.9}"
TOOLCHAIN_NAME="${TOOLCHAIN_NAME:-arm-linux-androideabi}"
TOOLCHAIN="${TOOLCHAIN:-${TOOLCHAIN_NAME}-4.9}"

URL="https://www.crystax.net/download/crystax-ndk-$VERSION-$BUILD.tar.xz"
TAR_NAME="`basename "$URL"`"
CRYSTAX_NAME="crystax-ndk-$VERSION"
SOURCES="./$CRYSTAX_NAME/sources"

INSTALL_DIR="$PWD/toolchain-$PLATFORM-$ABI-$COMPILER"
SYSROOT="$INSTALL_DIR/sysroot"
PREFIX="$SYSROOT/usr"

MAKE="${MAKE:-make}"
NDK_BUILD="${NDK_BUILD:-ndk-build -j4}"

PATH=$SYSROOT/../bin:$PATH

export PKG_CONFIG_SYSROOT_DIR=${SYSROOT}
export PKG_CONFIG_PATH=${SYSROOT}/usr/lib/pkgconfig:${SYSROOT}/usr/share/pkgconfig:${SYSROOT}/usr/lib/arm-linux-gnueabihf/pkgconfig/
export PKG_CONFIG=${TOOLCHAIN_NAME}-pkg-config

libxml2_build() {
    local patch=$PWD/patches/libxml2.sh
    pushd $libxml2_PATH
    test -e $patch && $patch
    test -e configure ||
        autoreconf -vi
    test -e Makefile ||
        ./configure \
            $CONFIGURE_QUIET \
            --host=$HOST \
            --prefix="$PREFIX" \
            "${libxml2_CONFIGURE[@]}"
    $MAKE $SILENT_RULES
    $MAKE install
    popd    
}

libxml2_clean() {
    pushd $libxml2_PATH
    $MAKE clean
    popd
}

libavg_build() {
    pushd $libavg_PATH
    local configure=${libavg_CONFIGURE:-}
    test -e configure ||
        ./bootstrap
    test -e Makefile ||
        ./configure \
            $CONFIGURE_QUIET \
            --host=$HOST \
            --prefix="$PREFIX" \
            "${configure[@]}"
    # build command         # dependencies
    libavg_tess_build       #
    libavg_base_build       # tess
    libavg_graphics_build   # base
    popd
}
libavg_tess_build() {
    pushd src/tess/
    $MAKE $SILENT_RULES
    popd
}
libavg_base_build() {
    pushd src/base/
    $MAKE $SILENT_RULES
    popd
}
libavg_graphics_build() {
    pushd src/graphics/
    $MAKE $SILENT_RULES
    popd
}

libSDL2_build() {
    pushd $libSDL2_PATH
    ./configure \
        $CONFIGURE_QUIET \
        --host=$HOST \
        --prefix="$PREFIX"
    $MAKE $SILENT_RULES -j4
    $MAKE install
    popd
}

main() {
    #libxml2_build
    #libSDL2_build
    libavg_build
}

main "${@:1}"
