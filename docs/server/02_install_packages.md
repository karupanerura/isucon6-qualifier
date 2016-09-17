# 便利パッケージのインストール

## OS系

```bash
sudo -H apt-get update
sudo -H apt-get upgrade -y
sudo -H apt-get install -y language-pack-ja
```

## ビルド系

```bash
sudo -H apt-get install -y build-essential pkg-config cmake autoconf
```

## ライブラリ系

```bash
sudo -H apt-get install -y libmysqlclient-dev libssl-dev libreadline-dev libxml2-dev libpcre3-dev
```

## ツール系

```bash
sudo -H apt-get install -y vim dstat tmux ngrep tcpdump snmpd curl wget git
```

## 画像系

### Image Magick

```bash
sudo -H apt-get install -y imagemagick
```

### ライブラリ系

```bash
sudo -H apt-get install -y libjpeg-dev libjpeg-turbo8-dev libpng12-dev libgif-dev libimlib2-dev libgd-dev
```

### mackerel-agent

```bash
curl -fsSL https://mackerel.io/assets/files/scripts/setup-apt.sh | sh
sudo -H apt-get install -y mackerel-agent mackerel-agent-plugins
```

### percona-toolkit

```bash
sudo -H gpg --keyserver  hkp://keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
sudo -H gpg -a --export CD2EFD2A | sudo -H apt-key add -
sudo -H bash -c 'echo "deb http://repo.percona.com/apt `lsb_release -cs` main" >> /etc/apt/sources.list.d/percona.list'
sudo -H bash -c 'echo "deb-src http://repo.percona.com/apt `lsb_release -cs` main" >> /etc/apt/sources.list.d/percona.list'
sudo -H apt-get update
sudo -H apt-get install -y percona-toolkit
```

## ミドルウェア系

### memcached

```bash
sudo -H apt-get install memcached
```

### redis

```bash
sudo -H apt-get install redis-server
```

### mysql

```bash
sudo -H apt-get install -y mysql-server mysql-common mysql-client
```

