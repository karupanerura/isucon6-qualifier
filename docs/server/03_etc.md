# 設定ファイル置き換え系

## mysqlの設定ファイル置き換え

```bash
mysql -uroot -e 'SET GLOBAL innodb_fast_shutdown=0'
sudo -H /etc/init.d/mysql stop
sudo -H mv /etc/mysql/my.cnf{,.bak}
sudo -H mv /etc/my.cnf{,.bak}
sudo -H ln /home/isucon/webapp/config/my.cnf /etc/mysql/my.cnf
sudo -H chown mysql:mysql /etc/mysql/my.cnf
sudo -H rm /var/lib/mysql/ib_logfile0 /var/lib/mysql/ib_logfile1
sudo -H /etc/init.d/mysql start
```

ポイント:

* デフォルトだと `/etc/my.cnf` にもファイルが置かれており、混乱するので `/etc/mysql/my.cnf` にまとめる。
  * ただしこれはtrustyのmysql packageの場合のはなし。他のバージョンでは違う可能性がある。
* `innodb_log_file_size` が変わることでInnoDBログが使えなくなるのでflashさせつつログファイルを削除し作りなおす必要がある。
  * SEE ALSO: http://masasuzu.hatenadiary.jp/entry/2014/06/13/innodb_log_file_size%E3%82%92%E6%B0%97%E8%BB%BD%E3%81%AB%E5%A4%89%E3%81%88%E3%82%8B%E3%81%A8%E6%AD%BB%E3%81%AC%E3%82%88

