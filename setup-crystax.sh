#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error when substituting.
#set -x # Print commands and their arguments as they are executed.

. preambel.sh

main() {
    echo "Edit ./preambel.sh for changes in version, platform, directories, etc."
    echo

    local minimal_crystax="-Xcrystax.tar-exclude"
    minimal_crystax=

    set -x
    test -e "$CRYSTAX_TAR_PATH" ||
        $RUN $WGET "$URL" -O "$CRYSTAX_TAR_PATH"
    test -e "$CRYSTAX_PATH" ||
        $RUN $TAR $minimal_crystax -x -a -f "$CRYSTAX_TAR_PATH" \
            --checkpoint=1000 --totals -C "$CRYSTAX_BASE_PATH"
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
    copy_stuff
    set +x
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
  $CRYSTAX_PATH/build/tools/make-standalone-toolchain.sh \
    --toolchain=$TOOLCHAIN \
    --install-dir=$INSTALL_DIR \
    --platform=$PLATFORM
}

copy_boost() {
    local version=$1
    $CP $SOURCES/boost/$version/include/* $SYSROOT$PREFIX/include
    $CP $SOURCES/boost/$version/libs/$ABI/$COMPILER/* $SYSROOT$PREFIX/lib
}

copy_python() {
    local version=$1
    mkdir -p $SYSROOT$PREFIX/{include,lib}/python$version/
    $CP $SOURCES/python/$version/include/python/* $SYSROOT$PREFIX/include/python$version/
    $CP $SOURCES/python/$version/libs/$ABI/*.so $SYSROOT$PREFIX/lib
    $CP \
        $SOURCES/python/$version/libs/$ABI/{modules,site-packages,stdlib.zip} \
        $SYSROOT$PREFIX/lib/python$version/
}

copy_icu() {
    local version=$1
    $CP $SOURCES/icu/$version/include/* $SYSROOT$PREFIX/include
    $CP $SOURCES/icu/$version/libs/$ABI/* $SYSROOT$PREFIX/lib
}

copy_stuff() {
    ln -fs /bin/false $INSTALL_DIR/bin/freetype-config
}

main "${@:1}"
