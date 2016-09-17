#!/bin/sh
set -eu

NGINX_VERSION=1.8.0
PCRE_VERSION=8.36
OPENSSL_VERSION=1.0.2d

wget -q http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz &
wget -q ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-$PCRE_VERSION.tar.bz2 &
wget -q https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz &
wait

tar zxf nginx-$NGINX_VERSION.tar.gz
tar jxf pcre-$PCRE_VERSION.tar.bz2
tar zxf openssl-$OPENSSL_VERSION.tar.gz
rm nginx-$NGINX_VERSION.tar.gz pcre-$PCRE_VERSION.tar.bz2 openssl-$OPENSSL_VERSION.tar.gz

mv pcre-$PCRE_VERSION nginx-$NGINX_VERSION
mv openssl-$OPENSSL_VERSION nginx-$NGINX_VERSION

cd nginx-$NGINX_VERSION
./configure \
    --with-pcre=pcre-$PCRE_VERSION --with-pcre-jit \
    --with-openssl=openssl-$OPENSSL_VERSION  --with-http_ssl_module \
    --without-mail_pop3_module --without-mail_imap_module --without-mail_smtp_module \
    --with-file-aio \
    --with-http_spdy_module \
    --with-http_gzip_static_module \
    --with-http_stub_status_module
make
sudo -H make install
