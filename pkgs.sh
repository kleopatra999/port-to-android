#!/bin/bash

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
    local path="${3:-"$PKGS_PATH"/`basestname "$2"`}"
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

libSDL2_TAR="https://libsdl.org/release/SDL2-2.0.4.tar.gz"
libSDL2_PATH="$PKGS_PATH/SDL2-2.0.4"
libSDL2_CONFIGURE=()

# TODO payload
# gettext need gperf
# gettext needs s/-lpthread//
#   but pthread_* is implemented in libcrystax.so
define_tar gettext \
    "http://ftp.gnu.org/pub/gnu/gettext/gettext-0.18.1.1.tar.gz" \
    "$PKGS_PATH/gettext-0.18.1.1"
define_tar libffi \
    "ftp://sourceware.org/pub/libffi/libffi-3.2.1.tar.gz" \
    "$PKGS_PATH/libffi-3.2.1"
    
true define_deb libpcre \
    "pcre3" \
    "$PKGS_PATH/pcre3-8.35"
define_tar libpcre \
    "ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.38.tar.bz2" \
    "$PKGS_PATH/pcre-8.38"

define_deb libpango \
    "libpango-1.0-0" \
    "$PKGS_PATH/pango1.0-1.36.8"


true define_deb cairo \
    "libcairo2" \
    "$PKGS_PATH/cairo-1.14.2"
# git://anonscm.debian.org/collab-maint/cairo.git    
# git://anongit.freedesktop.org/git/cairo
define_git cairo \
    "git://anonscm.debian.org/collab-maint/cairo.git" \
    "upstream/1.14.6" \
    "$PKGS_PATH/cairo"


define_deb pixman \
    "libpixman-1-0" \
    "$PKGS_PATH/pixman-0.32.6"
define_deb glib \
    "libglib2.0-0" \
    "$PKGS_PATH/glib2.0-2.46.1"
define_deb gdk_pixbuf \
    "libgdk-pixbuf2.0-0" \
    "$PKGS_PATH/gdk-pixbuf-2.32.1"


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
