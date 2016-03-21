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
    local cmds=${2:-configure|make|install}
    pushd $libavg_PATH
    if [[ configure =~ $cmds ]]
    then
        #rm -rf CMakeCache.txt CMakeFiles/
        #cmake \
        #    -DCMAKE_TOOLCHAIN_FILE=$pwd/Android.cmake \
        #    -DCMAKE_SYSROOT=$SYSROOT \
        #    -DCMAKE_C_COMPILER=$CC \
        #    -DCMAKE_CXX_COMPILER=$CXX \
        #    -DCMAKE_PREFIX_PATH=$PREFIX \
        #    .
        export PYTHON_CPPFLAGS="-I${SYSROOT}/usr/include/python2.7"
        export PYTHON_LDFLAGS="-L${SYSROOT}/usr/lib -L${SYSROOT}/usr/lib/python2.7/config/"
        export PYTHON_LIBS="-lpthread -ldl -lutil -lpython2.7"
        export PYTHON_EXTRA_LDFLAGS="-L${SYSROOT}/usr/lib -L${SYSROOT}/usr/lib/python2.7/config/"
        export PYTHON_EXTRA_LIBS="-ldl -lpython2.7"
        export PYTHON_NOVERSIONCHECK=1
        export PYTHON_SITE_PKG="${SYSROOT}/usr/lib/python2.7/dist-packages"
        ./bootstrap
        ./configure \
            $VERBOSE_CONFIGURE \
            --host=$HOST \
            --prefix=$PREFIX \
            --with-sysroot=$SYSROOT \
            --enable-egl \
            --disable-v4l2 \
            SDL_PATH=$pwd/$libSDL2_PATH \
            #
    fi &&
    if [[ make =~ $cmds ]]
    #then $MAKE $VERBOSE_CMAKE_MAKE -j -l$JOBS
    then $MAKE $VERBOSE_AUTOCONF_MAKE -j -l$JOBS
    fi &&
    if [[ install =~ $cmds ]]
    then $MAKE install DESTDIR=$DESTDIR
    fi
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
        --with-libpng \
        --without-libjpeg \
        --without-libtiff \
        -C
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
        --with-pcre=system \
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
    ask "gperf installed" || ( echo "you can also put `ln -s /bin/true gperf` into PATH"; return 1 )
    ask "patch" &&
    find . -type f -exec sed -i s/-lpthread// '{}' ';'
    ask "configure" &&
    ./configure \
        $VERBOSE_CONFIGURE \
        --host=$HOST \
        --prefix=$PREFIX \
        --disable-shared --with-included-gettext --disable-csharp  --disable-libasprintf -C --disable-acl --disable-java --disable-threads
    ask "make" &&
    $MAKE $VERBOSE_AUTOCONF_MAKE -j -l$JOBS 
    ask "install" &&
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

ffmpeg_build() {
    local name=ffmpeg
    local path=${name}_PATH
    pushd "${!path}"
    ./configure \
        --host=$HOST \
        --prefix=$PREFIX \
        --with-sysroot=$SYSROOT \
        --disable-debug \
        --disable-programs \
        --disable-shared -C &&
    $MAKE $VERBOSE_AUTOCONF_MAKE -j -l$JOBS &&
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
    $MAKE $VERBOSE_AUTOCONF_MAKE -j -l$JOBS DESTDIR="$DESTDIR" \
        install-libLTLIBRARIES \
        install-pkgconfigDATA \
        install-includeHEADERS \
        install-nodist_includeHEADERS \
        #
    popd
}

pango_build() {
    set -x
    local name=pango
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
        --disable-shared -C &&
    $MAKE $VERBOSE_AUTOCONF_MAKE -j -l$JOBS &&
    $MAKE install DESTDIR="$DESTDIR"
    popd
}

fontconfig_build() {
    set -x
    local name=fontconfig
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
        --enable-libxml2 \
        --disable-shared -C &&
    $MAKE $VERBOSE_AUTOCONF_MAKE -j -l$JOBS &&
    $MAKE install DESTDIR="$DESTDIR"
    popd
}

png_build() {
    set -xe
    local name=png
    local path=${name}_PATH
    pushd "${!path}"
    ./configure \
        $VERBOSE_CONFIGURE \
        --host=$HOST \
        --prefix=$PREFIX \
        --with-sysroot=$SYSROOT \
        --disable-shared \
        -C &&
    $MAKE $VERBOSE_AUTOCONF_MAKE -j -l$JOBS &&
    $MAKE install DESTDIR="$DESTDIR"
    popd
}

rsvg_build() {
    set -xe
    local name=rsvg
    local path=${name}_PATH
    pushd "${!path}"
    ./configure \
        $VERBOSE_CONFIGURE \
        --host=$HOST \
        --prefix=$PREFIX \
        --with-sysroot=$SYSROOT \
        --disable-introspection \
        --disable-shared \
        -C &&
    $MAKE $VERBOSE_AUTOCONF_MAKE -j -l$JOBS &&
    $MAKE install DESTDIR="$DESTDIR"
    popd
}

croco_build() {
    set -xe
    local name=croco
    local path=${name}_PATH
    pushd "${!path}"
    ./configure \
        $VERBOSE_CONFIGURE \
        --host=$HOST \
        --prefix=$PREFIX \
        --with-sysroot=$SYSROOT \
        --disable-shared \
        -C &&
    $MAKE $VERBOSE_AUTOCONF_MAKE -j -l$JOBS &&
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
        --enable-png \
        --disable-pdf \
        --disable-svg \
        --disable-ps \
        --disable-script \
        -C &&
    # options which might be okay or not:
    # not ok script     (weird link to glib error)
    #     ok ps
    #     ok png        (dependency)
    # 
    $MAKE $VERBOSE_AUTOCONF_MAKE -j -l$JOBS &&
    $MAKE install DESTDIR="$DESTDIR"
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

harfbuzz_build() {
    set -x
    local name=harfbuzz
    local path=${name}_PATH
    pushd "${!path}"
    #autoreconf --install -Wnone $VERBOSE_AUTORECONF
    ./configure \
        $VERBOSE_CONFIGURE \
        --host=$HOST \
        --prefix=$PREFIX \
        --with-sysroot=$SYSROOT \
        --disable-shared \
        --with-gobject \
        --with-freetype \
        -C
    $MAKE $VERBOSE_AUTOCONF_MAKE -j -l$JOBS
    $MAKE install DESTDIR="$DESTDIR"
    popd
}

freetype_build() {
    set -x
    local name=freetype
    local path=${name}_PATH
    pushd "${!path}"
    #autoreconf --install -Wnone $VERBOSE_AUTORECONF
    # http://www.linuxfromscratch.org/blfs/view/7.5/general/freetype2.html
    sed -i  -e "/AUX.*.gxvalid/s@^# @@" \
            -e "/AUX.*.otvalid/s@^# @@" \
            modules.cfg                        &&

    sed -ri -e 's:.*(#.*SUBPIXEL.*) .*:\1:' \
            include/config/ftoption.h          &&
    ./configure \
        $VERBOSE_CONFIGURE \
        --host=$HOST \
        --prefix=$PREFIX \
        --with-sysroot=$SYSROOT \
        --disable-shared \
        -C
    $MAKE $VERBOSE_AUTOCONF_MAKE -j -l$JOBS
    $MAKE install DESTDIR="$DESTDIR"
    popd
}

ask() {
    read -p "$1? [Yn] " && test -z $REPLY && return 0
    return 1
}

build() {
    ask $1 &&
    ( ${1}_build $@ |& tee ${1}_build.log ) || return 1
}

main() {
    set +e
    if test ${1:-}
    then build $1 ${2:-}
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
    
        build libavg
    fi
}

main "${@:1}"
