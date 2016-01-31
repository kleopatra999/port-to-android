#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error when substituting.
#set -x # Print commands and their arguments as they are executed.
shopt -s extglob

HOST=arm-linux-androideabi
VERBOSE=${VERBOSE:-}
if test -n "$VERBOSE"
then
    SILENT_RULES="V=1" # verbose make output
    CONFIGURE_QUIET=
    CMAKE_MAKE_VERBOSE="VERBOSE=1"
else
    SILENT_RULES="V=" # silent make output
    CONFIGURE_QUIET="--quiet"
    CMAKE_MAKE_VERBOSE="VERBOSE="
fi


cpus() {
    local cpus=1
    local os=`uname -s`
    if test $os -e Linux
    then cpus=`grep -c ^processor /proc/cpuinfo`
    elif test $os -e Darwin # Assume Mac OS X
    then cpus=`system_profiler | awk '/Number Of CPUs/{print $4}{next;}'`
    fi
    echo $cpus
}
JOBS=${JOBS:-`cpus`}

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
DESTDIR="$SYSROOT"
CC="$INSTALL_DIR/bin/$TOOLCHAIN_NAME-gcc"

MAKE="${MAKE:-make}"
NDK_BUILD="${NDK_BUILD:-ndk-build -j$JOBS}"

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
            "${libxml2_CONFIGURE[@]}"
    $MAKE $SILENT_RULES
    $MAKE install DESTDIR=$DESTDIR
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
    rm -rf CMakeCache.txt CMakeFiles/
    cmake \
        -DCMAKE_TOOLCHAIN_FILE=Android.cmake \
        -DCMAKE_SYSROOT=$SYSROOT \
        -DCMAKE_C_COMPILER=$CC \
        .
    $MAKE $CMAKE_MAKE_VERBOSE -j -l$JOBS
    $MAKE install DESTDIR=$DESTDIR
    popd
}

libSDL2_build() {
    pushd $libSDL2_PATH
    PKG_CONFIG_LIBDIR="${SYSROOT}/usr/lib/pkgconfig:${SYSROOT}/usr/share/pkgconfig" \
    PKG_CONFIG_SYSROOT_DIR="$SYSROOT" \
    ./configure \
        $CONFIGURE_QUIET \
        --host=$HOST
    $MAKE $SILENT_RULES -j$JOBS
    $MAKE install DESTDIR="$DESTDIR"
    popd
}

main() {
    #libxml2_build
    #libSDL2_build
    libavg_build
}

main "${@:1}"
