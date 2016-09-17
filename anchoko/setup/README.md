# 野良ビルド系置き場

# mysql-build

めんどいのでrootに入れてしまえ。

```sh
sudo -H su -
git clone git://github.com/kamipo/mysql-build.git $HOME/.mysql-build
```

## 使えそうなplugin

オーバーヘッドやバグなどのリスクを考慮して必要最小限のものだけ入れること。
ぶっちゃけ`mysql-build --plugins`で見れる。

* handlersocket-1.1.1
* q4m-master
* mroonga-4.05
* innodb-memcached

## e.g.) mysql 5.6.26
```sh
$HOME/.mysql-build/bin/mysql-build 5.6.26 /opt/mysql/5.6
```

## e.g.) mysql 5.6.26 && handlersocket-1.1.1
```sh
$HOME/.mysql-build/bin/mysql-build 5.6.26 /opt/mysql/5.6 handlersocket-1.1.1
```

## e.g.) mysql 5.6.26 && handlersocket-1.1.1 q4m-master
```sh
$HOME/.mysql-build/bin/mysql-build 5.6.26 /opt/mysql/5.6 handlersocket-1.1.1 q4m-master
```

# h2o

たぶん使わないけど一応 `setup/setup-h2o.sh` でビルドできるようになっている。
