# 鍵登録 & ユーザー登録

```bash
sudo -H su - isucon
ssh-keygen
cat .ssh/id_rsa.pub
git config --global user.email "karupa@cpan.org"
git config --global user.name "isucon"
git config --global push.default simple
```

# リポジトリへのファイルの追加

```bash
sudo -H su - isucon
cd webapp
git init
git remote add origin git@github.com:karupanerura/isucon6-qualifier.git
git fetch
git checkout -b master origin/master
git add .
git commit -m 'added webapp'
git push -u origin master
```
