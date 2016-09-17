#!/bin/sh
set -eu

PCRE_VERSION=8.36

wget -q ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-$PCRE_VERSION.tar.bz2
tar jxf pcre-$PCRE_VERSION.tar.bz2

cd pcre-$PCRE_VERSION
./configure --enable-jit
make
sudo -H make install
