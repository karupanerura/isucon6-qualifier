#!/bin/sh
set -eu

MEMCACHED_VERSION=1.4.24

#
# XXX: setup-libevent.shを先に実行する必要があります
#

wget -q http://memcached.org/files/memcached-$MEMCACHED_VERSION.tar.gz
tar xzf memcached-$MEMCACHED_VERSION.tar.gz
rm memcached-$MEMCACHED_VERSION.tar.gz

cd memcached-$MEMCACHED_VERSION
./configure --enable-64bit
make
sudo -H make install
