#!/bin/sh
set -eu

LIBEVENT_VERSION=2.0.22

wget -q https://github.com/downloads/libevent/libevent/libevent-$LIBEVENT_VERSION-stable.tar.gz
tar xzf libevent-$LIBEVENT_VERSION-stable.tar.gz
rm libevent-$LIBEVENT_VERSION-stable.tar.gz
cd libevent-$LIBEVENT_VERSION-stable
./configure --enable-static
make
sudo -H make install
