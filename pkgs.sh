#!/bin/bash

# NOTE: a good quality source for sources is the Linux from Scratch project
#       http://www.linuxfromscratch.org/lfs/view/development/index.html
#       http://www.linuxfromscratch.org/blfs/view/svn/index.html

PKGS=("libavg" "libxml2" "libSDL2" "gettext" "libffi" "libpcre" "glib"
pixman cairo libpango "gdk_pixbuf")
PKGS_PATH="modules"

define_git() { # name url branch path
    local path="${4:-"$PKGS_PATH"/`basestname "$2"`}"
    local gitclone="--depth 1 --branch $3 ""$2"" ""$path"
    declare -g \
        ${1}_GIT="$2" \
        ${1}_PATH="$path" \
        ${1}_GIT_CLONE="$gitclone"
}

define_tar() { # name url path
    # alternative: tar --list -a -f FILE | head -n1
    local path="${3:-"$PKGS_PATH"/`basename_no_tar "$2"`}"
    declare -g \
        ${1}_TAR="$2" \
        ${1}_PATH="$path"
}

define_deb() { # name pkg path
    local path="${3:-"$PKGS_PATH"/"$2"}"
    declare -g \
        ${1}_DEB="$2" \
        ${1}_PATH="$path"
}

libavg_GIT="git@github.com:payload/libavg.git"
# libavg_GIT="https://github.com/libavg/libavg.git"
libavg_PATH="$PKGS_PATH/libavg"
libavg_GIT_CLONE="--depth 1 --branch features/cmake-android $libavg_GIT $libavg_PATH"
libavg_CONFIGURE=()

libxml2_GIT="git://git.gnome.org/libxml2"
libxml2_PATH="$PKGS_PATH/libxml2"
libxml2_GIT_CLONE="--depth 1 --branch v2.9.3 $libxml2_GIT $libxml2_PATH"
libxml2_CONFIGURE=(
    --without-modules
    --without-legacy
    --without-history
    --without-debug
    --without-docbook
    --without-python
    --without-lzma
)

define_tar libSDL2 "https://libsdl.org/release/SDL2-2.0.4.tar.gz"
# TODO payload
# gettext need gperf
# gettext needs s/-lpthread//
#   but pthread_* is implemented in libcrystax.so
define_tar gettext "http://ftp.gnu.org/pub/gnu/gettext/gettext-0.18.1.1.tar.gz"
define_tar libffi "ftp://sourceware.org/pub/libffi/libffi-3.2.1.tar.gz"
define_tar libpcre "ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.38.tar.bz2"
define_tar libpango "http://ftp.gnome.org/pub/gnome/sources/pango/1.38/pango-1.38.1.tar.xz"
define_tar cairo "http://cairographics.org/releases/cairo-1.14.6.tar.xz"
define_tar pixman "http://cairographics.org/releases/pixman-0.34.0.tar.gz"
define_tar glib "http://ftp.gnome.org/pub/gnome/sources/glib/2.46/glib-2.46.2.tar.xz"
define_tar gdk_pixbuf "http://ftp.gnome.org/pub/gnome/sources/gdk-pixbuf/2.30/gdk-pixbuf-2.30.7.tar.xz"


#glib_GIT="https://github.com/GNOME/glib.git"
#glib_PATH="$PKGS_PATH/glib"
#glib_GIT_CLONE="--depth 1 --branch 2.29.2 $glib_GIT $glib_PATH"
#glib_CONFIGURE=(
#  --disable-shared
#  --enable-static 
#)

#gdk_pixbuf_GIT="https://github.com/payload/gdk-pixbuf.git"
#gdk_pixbuf_PATH="$PKGS_PATH/gdk-pixbuf"
#gdk_pixbuf_GIT_CLONE="--depth 1 --branch libavg $gdk_pixbuf_GIT $gdk_pixbuf_PATH"
