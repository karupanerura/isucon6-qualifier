Azure CLI インストール & VMのセットアップ
（とりあえず [isucon5-qualifier](https://github.com/matsuu/azure-isucon-templates/tree/master/isucon5-qualifier) で試したのを貼る）

## マニュアル
https://azure.microsoft.com/ja-jp/documentation/articles/xplat-cli-install/

### install
node / npm が必要

`npm install azure-cli -g`


### completion
必要なら

`echo '. <(azure --completion)' >> .zshrc`

### account settings

```
# 手で https://aka.ms/devicelogin にアクセスしてコードを入れる
azure login
> info:    login command OK

# リソースマネージャーモードにする（対: Azure サービス管理モード）
# デフォルトでarmなのでやらんでもよし
# https://azure.microsoft.com/ja-jp/documentation/articles/azure-classic-rm/
azure config mode arm
```

### deploy from template
CLIでやるよりポチポチするほうが楽そう

参考: https://azure.microsoft.com/ja-jp/documentation/articles/virtual-machines-linux-cli-deploy-templates/
![https://gyazo.com/a6e4bbae3f213b3c221f04e36a7e7d85]()

### ssh to VM
```
# vm show <group-name> <image>

$ azure vm list-ip-address
info:    Executing command vm list-ip-address
+ Getting virtual machines
+ Looking up the NIC "bench"
+ Looking up the public ip "bench"
+ Looking up the NIC "image"
+ Looking up the public ip "image"
+ Looking up the NIC "image_app"
+ Looking up the public ip "image_app"
+ Looking up the NIC "image_infra"
+ Looking up the public ip "image_infra"
data:    Resource Group        Name         Public IP Address
data:    --------------------  -----------  -----------------
data:    ISUCON5-QUALIFIER-01  bench        40.74.123.114
data:    ISUCON5-QUALIFIER-01  image        40.74.126.137
data:    ISUCON5-QUALIFIER-01  image_app    104.214.148.251
data:    ISUCON5-QUALIFIER-01  image_infra  40.74.95.219
info:    vm list-ip-address command OK

ssh <your-name>@104.214.148.251
```

### stop VM

```
# 一時停止したい場合（課金は継続されます！）
azure vm stop isucon5-qualifier-00 image
> warn: VM shutdown will not release the compute resources so you will be billed for the compute resources that this Virtual Machine uses.
って出てたけど見逃してた

# 課金を停止したい場合
azure vm deallocate isucon5-qualifier-00 image
```

ストレージの課金が継続されるのかは確認中。コンテナーとやらを削除してあげないと課金され続けそうな？

### チートシート

* `azure account list` : サブスクリプションIDが欲しい時
* `azure account set <subscription id>` : SETしておくと `-s` とか毎回付けなくて済むので楽
* `azure storage account list` : storageの情報が欲しければ
* `azure vm list` : vm の状態を見たいとき


