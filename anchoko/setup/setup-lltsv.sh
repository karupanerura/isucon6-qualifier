#!/bin/sh
set -eu

LLTSV_VERSION=v0.3.1

wget https://github.com/sonots/lltsv/releases/download/v0.3.1/lltsv_linux_amd64 -O lltsv
chmod +x lltsv
sudo -H mv lltsv /usr/local/bin/lltsv
