#!/bin/sh
set -eu

H2O_REVISION=v2.0.4

wget -q https://github.com/kazuho/h2o/archive/$H2O_REVISION.tar.gz
tar xzf $H2O_REVISION.tar.gz
rm $H2O_REVISION.tar.gz

cd h2o-$H2O_REVISION
cmake -DWITH_BUNDLED_SSL=on -DWITH_MRUBY=on -DCMAKE_INSTALL_PREFIX=/opt/h2o/$H2O_REVISION .
make
sudo -H make install
