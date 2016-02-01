CRYSTAX_VERSION="${CRYSTAX_VERSION:-10.3.1}"
BOOST_VERSIONS="1.59.0"
PYTHON_VERSIONS="2.7 3.5"
ICU_VERSIONS="56.1"
BUILD="${BUILD:-linux-x86_64}"

PLATFORM="${PLATFORM:-android-21}"
ABI="${ABI:-armeabi}"
COMPILER="${COMPILER:-gnu-4.9}"
HOST="arm-linux-androideabi"
TOOLCHAIN_NAME="${TOOLCHAIN_NAME:-$HOST}"
TOOLCHAIN="${TOOLCHAIN:-${TOOLCHAIN_NAME}-4.9}"

URL="https://www.crystax.net/download/crystax-ndk-$CRYSTAX_VERSION-$BUILD.tar.xz"
TAR_NAME="`basename "$URL"`"
CRYSTAX_NAME="crystax-ndk-$CRYSTAX_VERSION"
SOURCES="./$CRYSTAX_NAME/sources"

INSTALL_DIR="$PWD/toolchain-$PLATFORM-$ABI-$COMPILER"
SYSROOT="$INSTALL_DIR/sysroot"
DESTDIR="$SYSROOT"
PREFIX="/usr"
CC="$INSTALL_DIR/bin/$TOOLCHAIN_NAME-gcc"

cpus() {
    local cpus=1
    local os=`uname -s`
    if test $os = Linux
    then cpus=`grep -c ^processor /proc/cpuinfo`
    elif test $os = Darwin # Assume Mac OS X
    then cpus=`system_profiler | awk '/Number Of CPUs/{print $4}{next;}'`
    fi
    echo $cpus
}
JOBS=${JOBS:-`cpus`}

RUN=${SILENT:-run}
test ${DRY:-} && RUN=echo

MAKE="${MAKE:-make}"
NDK_BUILD="${NDK_BUILD:-ndk-build -j$JOBS}"
WGET=${WGET:-wget}
TAR=${TAR:-tar}
CP=${CP:-ln -r}

PATH=$SYSROOT/../bin:$PATH

export PKG_CONFIG_SYSROOT_DIR="${SYSROOT}"
export PKG_CONFIG_LIBDIR="${SYSROOT}/usr/lib/pkgconfig:${SYSROOT}/usr/share/pkgconfig"
export PKG_CONFIG=pkg-config

run() {
    echo "# $@" >&2
    "$@"
}

basestname() {
    local name=`basename "$1"`
    echo ${name%%.*}
}
