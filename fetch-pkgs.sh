#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error when substituting.
#set -x # Print commands and their arguments as they are executed.

. preambel.sh
. pkgs.sh

fetch-pkg() {
    set +ue
    local pkg=${1}
    pkg_PATH=${pkg}_PATH
    pkg_PATH=${!pkg_PATH}
    pkg_GIT=${pkg}_GIT
    pkg_GIT=${!pkg_GIT}
    pkg_TAR=${pkg}_TAR
    pkg_TAR=${!pkg_TAR}
    pkg_DEB=${pkg}_DEB
    pkg_DEB=${!pkg_DEB}
    if test -e $pkg_PATH
    then printf "%-16s exists\n" $pkg
    elif test $pkg_GIT
    then git_clone ${pkg}_GIT_CLONE
    elif test $pkg_TAR
    then wget_tar $pkg_TAR $pkg_PATH
    elif test $pkg_DEB
    then apt_get_source $pkg_DEB $pkg_PATH
    fi
}

git_clone() {
    $RUN git clone ${!1}
}

wget_tar() {
    local zip url="$1" dir="`dirname $2`"
    case ${url##*.} in
        gz)     zip=--gzip  ;;
        xz)     zip=--xz    ;;
        bz2)    zip=--bzip2 ;;
    esac
    $RUN wget -O - $url |
        $RUN tar -x $zip -C $dir
}

apt_get_source() {
    local tmp=`mktemp -d`
    pushd $tmp
    $RUN apt-get source $1
    rm *.dsc *.gz *.xz
    mv $1* $1
    popd
    pushd `dirname $2`
    mv $tmp/* .
    popd
}

main() {
    local pkgs=${@:-${PKGS[@]}}
    for pkg in $pkgs
    do fetch-pkg $pkg
    done
}

main "${@:1}"
