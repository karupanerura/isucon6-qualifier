# install

```bash
brew install ansible
```

# ホスト情報を更新

```bash
bin/update-hosts.pl > hosts
```

# run

## 初回構築

```bash
ansible-playbook -i hosts playbook.yaml --tags init
```

## nginx

```bash
ansible-playbook -i hosts playbook.yaml --tags nginx
```

## mysql

```bash
ansible-playbook -i hosts playbook.yaml --tags mysql
```

## supervisor

```bash
ansible-playbook -i hosts playbook.yaml --tags supervisor
```
