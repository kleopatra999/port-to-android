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
            --with-sysroot=$SYSROOT \
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
    local pwd=$PWD
    pushd $libavg_PATH
    local configure=${libavg_CONFIGURE:-}
    rm -rf CMakeCache.txt CMakeFiles/
    cmake \
        -DCMAKE_TOOLCHAIN_FILE=$pwd/Android.cmake \
        -DCMAKE_SYSROOT=$SYSROOT \
        -DCMAKE_C_COMPILER=$CC \
        -DCMAKE_CXX_COMPILER=/home/payload/Code/android/cmake-android/toolchain-android-21-armeabi-gnu-4.9/bin/arm-linux-androideabi-g++ \
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
        --prefix=$PREFIX \
        --with-sysroot=$SYSROOT \
        #
    $MAKE $VERBOSE_AUTOCONF_MAKE -j -l$JOBS
    $MAKE install DESTDIR="$DESTDIR"
    popd
}

gdk_pixbuf_build() {
    set -ex
    local name=gdk_pixbuf
    local path=${name}_PATH
    local patch=$PWD/patches/$name.sh
    pushd ${!path}
    test -f $patch && $patch
    #autoreconf --force --install $VERBOSE_AUTORECONF
    #./autogen.sh
    ./configure \
        $VERBOSE_CONFIGURE \
        --host=$HOST \
        --prefix=$PREFIX \
        --with-sysroot=$SYSROOT \
        --disable-shared \
        --disable-gio-sniffing \
        --disable-modules \
        --disable-relocations \
        --without-libpng \
        --without-libjpeg \
        --without-libtiff \
        -C
    # XXX maybe needs libpng etc detection, possibly .pc files
    #     check this one at a time
    $MAKE $VERBOSE_AUTOCONF_MAKE -j -l$JOBS
    $MAKE install DESTDIR="$DESTDIR"
    popd
}

glib_build() {
    set -x
    local name=glib
    local path=${name}_PATH
    local config_cache=patches/$name-android.configure-cache
    test -e "$config_cache" &&
        cat "$config_cache" >> ${!path}/config.cache
    pushd "${!path}"
    #test -e ./configure ||
    #    AUTOMAKE="${AUTOMAKE:-automake} --foreign" \
    #    autoreconf --install -Wnone $VERBOSE_AUTORECONF
    #./autogen.sh
    ./configure \
        $VERBOSE_CONFIGURE \
        --host=$HOST \
        --prefix=$PREFIX \
        --with-sysroot=$SYSROOT \
        -C \
        --disable-shared
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

libffi_build() {
    set -x
    local name=libffi
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
        --with-sysroot=$SYSROOT \
        --disable-shared -C
    $MAKE $VERBOSE_AUTOCONF_MAKE -j -l$JOBS
    $MAKE install DESTDIR="$DESTDIR"
    popd
}

libpcre_build() {
    set -x
    local name=libpcre
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
        --with-sysroot=$SYSROOT \
        --disable-shared -C
    $MAKE $VERBOSE_AUTOCONF_MAKE -j -l$JOBS
    $MAKE install DESTDIR="$DESTDIR"
    popd
}

libpango_build() {
    set -x
    local name=libpango
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
        --with-sysroot=$SYSROOT \
        --disable-shared -C
    #./configure
    $MAKE $VERBOSE_AUTOCONF_MAKE -j -l$JOBS
    $MAKE install DESTDIR="$DESTDIR"
    popd
}

cairo_build() {
    set -xe
    local name=cairo
    local path=${name}_PATH
    pushd "${!path}"
    #./autogefn.sh
    #touch gtk-doc.make
    #AUTOMAKE="${AUTOMAKE:-automake} --foreign" \
    #autoreconf --force -Wnone $VERBOSE_AUTORECONF
    #test configure -nt Makefile &&
    ./configure \
        $VERBOSE_CONFIGURE \
        --host=$HOST \
        --prefix=$PREFIX \
        --with-sysroot=$SYSROOT \
        --disable-shared \
        --enable-glesv2 \
        --disable-png \
        --disable-pdf \
        --disable-svg \
        --disable-ps \
        --disable-script \
        -C
    # options which might be okay or not:
    # not ok script     (weird link to glib error)
    #     ok ps
    # not ok png        (needs libpng.pc)
    # 
    $MAKE $VERBOSE_AUTOCONF_MAKE -j -l$JOBS
    #$MAKE install DESTDIR="$DESTDIR"
    popd
}

pixman_build() {
    set -x
    local name=pixman
    local path=${name}_PATH
    pushd "${!path}"
    #./autogen.sh
    #touch gtk-doc.make
    #AUTOMAKE="${AUTOMAKE:-automake} --foreign" \
    #autoreconf --install -Wnone $VERBOSE_AUTORECONF
    test configure -nt Makefile &&
        ./configure \
            $VERBOSE_CONFIGURE \
            --host=$HOST \
            --prefix=$PREFIX \
            --with-sysroot=$SYSROOT \
            --disable-shared \
            --disable-arm-simd \
            --disable-arm-neon \
            --disable-arm-iwmmxt \
            -C
    # XXX cpu-features.h of crystax not like pixman on android thinks it is
    # thats why --disable-arm-* is done
    $MAKE $VERBOSE_AUTOCONF_MAKE -j -l$JOBS
    $MAKE install DESTDIR="$DESTDIR"
    popd
}

build() {
    ( ${1}_build |& tee ${1}_build.log ) || exit 1
}

main() {
    set -ex
    if test ${1:-}
    then build $1
    else
        build libxml2
        build libSDL2
        
        build gettext
        build libffi
        build libpcre
        build glib
        
        #build pixman
        #build cairo
        #build libpango
        build gdk_pixbuf
    
        #build libavg
    fi
}

main "${@:1}"
