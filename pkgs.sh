#!/bin/bash

PKGS=("crystax_tests" "libavg" "libxml2" "libSDL2" "gettext" "glib" "gdk_pixbuf")
PKGS_PATH="modules"

define_git() {
    local path="$PKGS_PATH"/`basestname "$2"`
    local gitclone="--depth 1 --branch $3 ""$2"" ""$path"
    declare -g \
        ${1}_GIT="$2" \
        ${1}_PATH="$path" \
        ${1}_GIT_CLONE="$gitclone"
}

define_tar() {
    local path="${3:-"$PKGS_PATH"/`basestname "$2"`}"
    declare -g \
        ${1}_TAR="$2" \
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

define_git crystax_tests "crystax-tests" master

glib_GIT="https://github.com/GNOME/glib.git"
glib_PATH="$PKGS_PATH/glib"
glib_GIT_CLONE="--depth 1 --branch 2.29.2 $glib_GIT $glib_PATH"

gdk_pixbuf_GIT="https://github.com/payload/gdk-pixbuf.git"
gdk_pixbuf_PATH="$PKGS_PATH/gdk-pixbuf"
gdk_pixbuf_GIT_CLONE="--depth 1 --branch libavg $gdk_pixbuf_GIT $gdk_pixbuf_PATH"
