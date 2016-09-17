# 事前準備

## ルールの事前把握

事前に把握できる情報はなるべく把握しておく。

* [開催概要/注意事項](http://isucon.net/archives/45166655.html)
* [レギュレーション](http://isucon.net/archives/45347574.html)

## Goolge Cloud Platformの利用準備

以下のドキュメントをもとに自分用にプロジェクトを作り、ISUCON4のインスタンスを立ち上げてブラウザでアクセス出来ることを確認するところまでやっておく。  
[ISUCON参加者向け Google Cloud Platform (GCP)の使い方](http://isucon.net/archives/45253058.html)

## 椅子/モニター

もしかしたら余っている(orだれかの)やつをあらたまさんに貸せるかもしれないので聞いておく。    
こばけんとか快諾してくれそう。

## チートシート/ツール類/秘伝のタレの用意

09/26(土)までには用意します…。 :bow:  
[kamipoさんのやつ](https://github.com/kamipo/isucon4anchoco)みたいなのを想定しておいてくだされー。

# 当日準備

## 飲み物、おやつ

競技前に買っておくと良い。おやつは300円まで！（※うそです）

## お昼ごはん

当日の気分で。必要に応じて事前に寿司などの出前を取る。

## 気分を高める

なにか気分が高まるアイディアを募集しています！

## gcloudの設定

Goolge Cloud Platformの利用準備の過程でgcloudをインストールするはず。  
projectは `isucon5-qualifier-oniyanma` 、zoneは `asia-east1-c` に設定しておく。  
すると `gcloud compute ssh` などがスムーズに出来るようになる。べんり。

```bash
gcloud config set project isucon5-qualifier-oniyanma
gcloud config set compute/zone asia-east1-c
```

## インスタンス名の確認

ベンチ用 | karupanerura開発用 | ar_tama開発用 | silvers開発用
-------- | ------------------ | ------------- | -------------
bench    | karupanerura       | ar-tama       | silvers

`gcloud compute ssh bench` などとカジュアルに繋ぐことが出来るのが理想。
