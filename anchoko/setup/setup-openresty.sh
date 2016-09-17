#!/bin/sh
set -eu

OPENRESTY_VERSION=1.9.3.1
PCRE_VERSION=8.36
OPENSSL_VERSION=1.0.2d

wget -q https://openresty.org/download/ngx_openresty-$OPENRESTY_VERSION.tar.gz
wget -q ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-$PCRE_VERSION.tar.bz2 &
wget -q https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz &
wait

tar zxf ngx_openresty-$OPENRESTY_VERSION.tar.gz
tar jxf pcre-$PCRE_VERSION.tar.bz2
tar zxf openssl-$OPENSSL_VERSION.tar.gz
rm ngx_openresty-$OPENRESTY_VERSION.tar.gz pcre-$PCRE_VERSION.tar.bz2 openssl-$OPENSSL_VERSION.tar.gz

mv pcre-$PCRE_VERSION ngx_openresty-$OPENRESTY_VERSION
mv openssl-$OPENSSL_VERSION ngx_openresty-$OPENRESTY_VERSION

cd ngx_openresty-$OPENRESTY_VERSION
./configure \
    --prefix=/opt/openresty/$OPENRESTY_VERSION \
    --with-pcre=pcre-$PCRE_VERSION --with-pcre-jit \
    --with-openssl=openssl-$OPENSSL_VERSION  --with-http_ssl_module \
    --without-mail_pop3_module --without-mail_imap_module --without-mail_smtp_module \
    --with-luajit \
    --with-file-aio \
    --with-http_spdy_module \
    --with-http_gzip_static_module \
    --with-http_stub_status_module
make
sudo -H make install
