#!/bin/bash

PKGS=("libavg" "libxml2" "libSDL2")
PKGS_PATH="modules"

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
