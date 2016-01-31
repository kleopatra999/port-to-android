#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error when substituting.
#set -x # Print commands and their arguments as they are executed.

VERSION="${VERSION:-10.3.1}"
BUILD="${BUILD:-linux-x86_64}"

PLATFORM="${PLATFORM:-android-21}"
ABI="${ABI:-armeabi}"
COMPILER="${COMPILER:-gnu-4.9}"
TOOLCHAIN="${TOOLCHAIN:-arm-linux-androideabi-4.9}"

URL="https://www.crystax.net/download/crystax-ndk-$VERSION-$BUILD.tar.xz"
TAR_NAME="`basename "$URL"`"
CRYSTAX_NAME="crystax-ndk-$VERSION"
SOURCES="./$CRYSTAX_NAME/sources"

INSTALL_DIR="$PWD/toolchain-$PLATFORM-$ABI-$COMPILER"
SYSROOT="$INSTALL_DIR/sysroot"
PREFIX="$SYSROOT/usr"

WGET=${WGET:-wget}
TAR=${TAR:-tar}
CP=${CP:-ln -r}

main() {
    echo "Edit this file for changes in version, platform, directories, etc."
    echo
    test -e "$TAR_NAME" ||
        $WGET "$URL" "$TAR_NAME"
    test -e "$CRYSTAX_NAME" ||
        $TAR -Xcrystax.tar-exclude -x -a -v -f "$TAR_NAME"
    test -e "$INSTALL_DIR" ||
        make_standalone_toolchain
    copy_boost 1.59.0
    copy_python 2.7
    copy_python 3.5
    copy_icu 56.1
}

make_standalone_toolchain() {
  # --help                   Print this help.
  # --verbose                Enable verbose mode.
  # --dryrun                 Set to dryrun mode.
  # --toolchain=<name>       Specify toolchain name
  # --llvm-version=<ver>     Specify LLVM version
  # --stl=<name>             Specify C++ STL [gnustl]
  # --arch=<name>            Specify target architecture
  # --abis=<list>            Specify list of target ABIs.
  # --ndk-dir=<path>         Take source files from NDK at <path> [./crystax-ndk-$VERSION]
  # --system=<name>          Specify host system [linux-x86_64]
  # --package-dir=<path>     Place package file in <path> [/tmp/ndk-payload]
  # --install-dir=<path>     Don't create package, install files to <path> instead.
  # --platform=<name>        Specify target Android platform/API level. [android-3]
  ./$CRYSTAX_NAME/build/tools/make-standalone-toolchain.sh \
    --toolchain=$TOOLCHAIN \
    --install-dir=$INSTALL_DIR \
    --platform=$PLATFORM
}

copy_boost() {
    local version=$1
    $CP -fs $SOURCES/boost/$version/include/* $PREFIX/include
    $CP -fs $SOURCES/boost/$version/libs/$ABI/$COMPILER/* $PREFIX/lib
}

copy_python() {
    local version=$1
    mkdir -p $PREFIX/lib/python$version/
    $CP -fs $SOURCES/python/$version/include/* $PREFIX/include
    $CP -fs $SOURCES/python/$version/libs/$ABI/*.so $PREFIX/lib
    $CP -fs \
        $SOURCES/python/$version/libs/$ABI/{modules,site-packags,stdlib.zip} \
        $PREFIX/lib/python$version/
}

copy_icu() {
    local version=$1
    $CP -fs $SOURCES/icu/$version/include/* $PREFIX/include
    $CP -fs $SOURCES/icu/$version/libs/$ABI/* $PREFIX/lib
}

main "${@:1}"
