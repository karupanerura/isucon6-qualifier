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
azure vm show isucon5-qualifier-00 image
> data:    Network Profile:
> data:      Network Interfaces:
> data:        Network Interface #1:
> data:          Primary                   :true
> data:          MAC Address               :00-0D-3A-50-68-28
> data:          Provisioning State        :Succeeded
> data:          Name                      :image
> data:          Location                  :japaneast
> data:            Public IP address       :13.78.91.251
> data:
> data:    Diagnostics Instance View:
> info:    vm show command OK

ssh isucon@13.78.91.251
# あとはよしなに
```

