# ISUCON6あんちょこ

## スロークエリログの分析

設定は https://github.com/karupanerura/isucon6-qualifier/blob/master/config/mysqld.cnf を確認すること

### 時間順に出す

```bash
sudo -H mysqldumpslow -s t /tmp/mysql-slow.log
```

### 回数順に出す

```bash
sudo -H mysqldumpslow -s c /tmp/mysql-slow.log
```

### digest

```bash
sudo -H pt-query-digest /tmp/mysql-slow.log
```

## アクセスログの分析

https://github.com/tkuchiki/alp

```bash
alp -f /tmp/nginx.access.log
alp -f /tmp/nginx.access.log --sum
alp -f /tmp/nginx.access.log --cnt
alp -f /tmp/nginx.access.log --start-time "11:45:39+09:00"
alp -f /tmp/nginx.access.log --start-time-duration 2m
alp -f /tmp/nginx.access.log --aggregates "/diary/entry/\d+"
```

## ログのローテート

```bash
sudo -H logrotate.pl nginx /var/log/nginx/access.log
sudo -H logrotate.pl mysql /tmp/mysql-slow.log
```

## コンフィグテスト

```bash
sudo -H /home/isucon/nginx/sbin/nginx -t
```

## nginx

```bash
systemctl restart nginx
```

## mysql

```bash
systemctl restart mysql
```

## gzip圧縮

```bash
gzip -r js css
gzip -k index.html
```

## netstat

```bash
sudo -H netstat -tlnp
sudo -H netstat -tnp | grep ESTABLISHED
```

## lsof

```bash
sudo -H lsof -nP -i4TCP -sTCP:LISTEN
sudo -H lsof -nP -i4TCP -sTCP:ESTABLISHED
```

## iostat

```bash
sudo -H iostat -d -x -t 2
```

## pidstat

```bash
pidstat -d -t -p $PID 2 # IO
pidstat -s -t -p $PID 2 # CPU
pidstat -u -t -p $PID 2 # STACK
pidstat -r -t -p $PID 2 # MEMORY
pidstat -v -t -p $PID 2 # KERNEL
```
