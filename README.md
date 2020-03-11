# docker_samba4-ac
DockerでSAMBA4を動かし、ActiveDirectory Domain Controllerにします。

https://github.com/Fmstrat/samba-domain/ をベースに作成


使い方はリポジトリにあるdocker-compose.ymlを参照

今のところ、ユーザの登録削除、WindowsからのAD参加位しか動きません。

RPCサーバが動いていないとかちょくちょく謎のエラーがでますが、設定が悪いのかDockerで動かすのが上手くいかないのかconfigureのオプションが足りないのか？？

[ここ](https://www.tecmint.com/manage-samba4-dns-group-policy-from-windows/)を見る感じDNSもGroup Policyも機能するっぽいんだけどなぁ。。。



