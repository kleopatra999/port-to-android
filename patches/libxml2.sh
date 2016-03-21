#/bin/sh
git checkout .
make distclean
sed -i 's/noinst_/\# noinst_/i' Makefile.am
