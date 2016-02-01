#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error when substituting.
#set -x # Print commands and their arguments as they are executed.
shopt -s extglob

. preambel.sh
. pkgs.sh

VERBOSE=${VERBOSE:-}
if test -n "$VERBOSE"
then
    VERBOSE_CONFIGURE=
    VERBOSE_CMAKE_MAKE="VERBOSE=1"
    VERBOSE_AUTORECONF="--verbose"
    VERBOSE_AUTOCONF_MAKE="V=1"
else
    VERBOSE_CONFIGURE="--quiet"
    VERBOSE_CMAKE_MAKE="VERBOSE="
    VERBOSE_AUTORECONF=""
    VERBOSE_AUTOCONF_MAKE="V=0"
fi

libxml2_build() {
    local patch=$PWD/patches/libxml2.sh
    pushd $libxml2_PATH
    test -e $patch && $patch
    test -e configure ||
        autoreconf -vi
    test -e Makefile ||
        ./configure \
            $VERBOSE_CONFIGURE \
            --host=$HOST \
            --prefix=$PREFIX \
            "${libxml2_CONFIGURE[@]}"
    $MAKE $VERBOSE_AUTOCONF_MAKE -j -l$JOBS
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
        -DCMAKE_PREFIX_PATH=$PREFIX \
        .
    $MAKE $VERBOSE_CMAKE_MAKE -j -l$JOBS
    $MAKE install DESTDIR=$DESTDIR
    popd
}

libSDL2_build() {
    pushd $libSDL2_PATH
    ./configure \
        $VERBOSE_CONFIGURE \
        --host=$HOST \
        --prefix=$PREFIX
    $MAKE $VERBOSE_AUTOCONF_MAKE -j -l$JOBS
    $MAKE install DESTDIR="$DESTDIR"
    popd
}

gdk_pixbuf_build() {
    set -x
    pushd $gdk_pixbuf_PATH
    #autoreconf --force --install $VERBOSE_AUTORECONF
    ./configure \
        $VERBOSE_CONFIGURE \
        --host=$HOST \
        --prefix=$PREFIX \
        --disable-shared --with-included-loaders
    $MAKE $VERBOSE_AUTOCONF_MAKE -j -l$JOBS
    $MAKE install DESTDIR="$DESTDIR"
    popd
}

glib_build() {
    set -x
    local name=glib
    local path=${name}_PATH
    pushd "${!path}"
    touch gtk-doc.make
    test -e ./configure ||
        AUTOMAKE="${AUTOMAKE:-automake} --foreign" \
        autoreconf --install -Wnone $VERBOSE_AUTORECONF
    ./configure \
        $VERBOSE_CONFIGURE \
        --host=$HOST \
        --prefix=$PREFIX \
        -C --disable-shared --enable-static 
    $MAKE $VERBOSE_AUTOCONF_MAKE -j -l$JOBS
    $MAKE install DESTDIR="$DESTDIR"
    popd
}

gettext_build() {
    set -x
    local name=gettext
    local path=${name}_PATH
    pushd "${!path}"
    #./autogen.sh
    #touch gtk-doc.make
    #AUTOMAKE="${AUTOMAKE:-automake} --foreign" \
    #autoreconf --install -Wnone $VERBOSE_AUTORECONF
    ./configure \
        $VERBOSE_CONFIGURE \
        --host=$HOST \
        --prefix=$PREFIX \
        --disable-shared --with-included-gettext --disable-csharp  --disable-libasprintf -C --disable-acl --disable-java --disable-threads
    $MAKE $VERBOSE_AUTOCONF_MAKE -j -l$JOBS
    $MAKE install DESTDIR="$DESTDIR"
    popd
}

crystax_tests_build() {
    local name=crystax_tests
    local path=${name}_PATH
    pushd "${!path}"
    rm -rf CMakeCache.txt CMakeFiles/
    cmake \
        -DCMAKE_SYSTEM_NAME=Android \
        -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
        -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY \
        -DCMAKE_SYSROOT=$SYSROOT \
        -DCMAKE_C_COMPILER=$CC \
        -DCMAKE_PREFIX_PATH=$PREFIX \
        .
    $MAKE $VERBOSE_CMAKE_MAKE -j -l$JOBS
    #$MAKE install DESTDIR=$DESTDIR
    popd
}

main() {
    crystax_tests_build
    libxml2_build
    libSDL2_build
    gettext_build
    glib_build
    gdk_pixbuf_build
    libavg_build
}

main "${@:1}"
