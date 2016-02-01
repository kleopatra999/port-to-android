#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error when substituting.
#set -x # Print commands and their arguments as they are executed.

. preambel.sh

main() {
    echo "Edit ./preambel.sh for changes in version, platform, directories, etc."
    echo
    test -e "$TAR_NAME" ||
        $RUN $WGET "$URL" "$TAR_NAME"
    test -e "$CRYSTAX_NAME" ||
        $RUN $TAR -Xcrystax.tar-exclude -x -a -v -f "$TAR_NAME"
    test -e "$INSTALL_DIR" ||
        make_standalone_toolchain
    for v in $BOOST_VERSIONS
    do copy_boost $v
    done
    for v in $PYTHON_VERSIONS
    do copy_python $v
    done
    for v in $ICU_VERSIONS
    do copy_icu $v
    done
    echo "toolchain exists in $INSTALL_DIR"
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
  # --ndk-dir=<path>         Take source files from NDK at <path> [./crystax-ndk-$CRYSTAX_VERSION]
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
    $CP -fs $SOURCES/boost/$version/include/* $SYSROOT$PREFIX/include
    $CP -fs $SOURCES/boost/$version/libs/$ABI/$COMPILER/* $SYSROOT$PREFIX/lib
}

copy_python() {
    local version=$1
    mkdir -p $SYSROOT$PREFIX/lib/python$version/
    $CP -fs $SOURCES/python/$version/include/* $SYSROOT$PREFIX/include
    $CP -fs $SOURCES/python/$version/libs/$ABI/*.so $SYSROOT$PREFIX/lib
    $CP -fs \
        $SOURCES/python/$version/libs/$ABI/{modules,site-packags,stdlib.zip} \
        $SYSROOT$PREFIX/lib/python$version/
}

copy_icu() {
    local version=$1
    $CP -fs $SOURCES/icu/$version/include/* $SYSROOT$PREFIX/include
    $CP -fs $SOURCES/icu/$version/libs/$ABI/* $SYSROOT$PREFIX/lib
}

main "${@:1}"
