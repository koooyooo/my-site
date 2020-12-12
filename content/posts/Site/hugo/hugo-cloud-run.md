---
title: "Hugo Cloud Run"
date: 2020-12-12T02:45:19+09:00
draft: false
---

## Cloud Load Balancing x GCS の課題
GCS x Cloud LB によるHugoのホスティングは問題なく稼働していたものの、LBの常時稼働によるコストは日額で63円程掛かります。月額に換算すると1830円、静的サイトをホスティングするにしては安くはない金額です。WordPressのホスティングなら、多少サービスの良い業者でも月額1000円程度、その2倍近く掛かってしまうのは設計的に良かったとしても、あまり人に勧められる選択ではありません。

もちろん、HTTPS化を諦めてGCS単体でホスティングすれば十分に低コストになるでしょう。ただ全てがSSL/TLS化されてきている現状で、暗号化なしという選択はそれはそれで違和感が拭えません。

GCSの提供するWebサイトホスティングの機能(index.html等のコール)はCloudLoadBalancing経由かDNS経由でコールしない限り効果を発揮しません。LBは高コスト・DNS経由は非暗号、となると GCSを離れた第3の選択肢を考えなければなりません。

## Cloud Run の適性

そこで思いついたのが、Cloud Runによるホスティングです。Cloud Runは HTTPSに対応しており、且つ低価格です。低価格な理由はアクセスが少ない時にはコンテナを停止できるからです。またCPUなら毎月 180,000vCPU秒, メモリは 360,000GiB秒, リクエストは 2,000,000リクエストまで無料という無料枠までついてきます。(最新の情報は [Cloud Run 料金](https://cloud.google.com/run/pricing/?hl=ja)を参照)

また利用も非常に簡単で、基本的にはコンテナをレジストリに登録し、それを起動コンテナとして指定するだけです。一般的なWebアプリケーションやAPIであれば、ストレージとの繋ぎ込みくらいの労力は必要ですが、今回の場合はそれすら不要です。一度起動したコンテナのコンテンツは更新されませんし、負荷が掛かって10台・100台とスケールアウトしようと、コンテナ間の内容に齟齬がでることはありません。

ではコンテンツを更新したくなったらどうするのか、その場合は内容が異なる別バージョンのイメージを用意しそれを指定するだけです。しかし、理論通りに動くか、本当に課題が無いのかは分かりません。そこで、実際に構築してみることにしました。

## Cloud Runの設定
### Dockerfile
イメージを作成する Dockerfileは非常に簡単です。`Hugo`が `public`ディレクトリ内に出力した静的コンテンツをドキュメントルートである`/usr/share/nginx/html`に配置して、通常どおりに起動するだけです。

```shell
$ hugo 
Start building sites … 

                   | EN  
-------------------+-----
  Pages            | 26  
  Paginator pages  |  0  
  Non-page files   |  6  
  Static files     | 35  
  Processed images |  0  
  Aliases          |  9  
  Sitemaps         |  1  
  Cleaned          |  0  

Total in 280 ms
```

```docker

FROM nginx:1.19-alpine

COPY ./public /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

```

### Local環境の動作確認
一応動作確認をしてみます。この`Dockerfile`を利用してコンテナをビルド・実行してから…

```shell
% docker build -t my-server .

Sending build context to Docker daemon  40.74MB
Step 1/4 : FROM nginx:1.19-alpine
 ---> 98ab35023fd6
Step 2/4 : COPY ./public /usr/share/nginx/html
 ---> 6876dfa2dd05
Step 3/4 : EXPOSE 80
 ---> Running in 7c952d655572
Removing intermediate container 7c952d655572
 ---> 89165b49b0e7
Step 4/4 : CMD ["nginx", "-g", "daemon off;"]
 ---> Running in 69b125f81e71
Removing intermediate container 69b125f81e71
 ---> 26cd963c07bc
Successfully built 26cd963c07bc
Successfully tagged my-server:latest
```

```shell
% docker run --rm -p 80:80 my-server

/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: Getting the checksum of /etc/nginx/conf.d/default.conf
10-listen-on-ipv6-by-default.sh: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
/docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
/docker-entrypoint.sh: Configuration complete; ready for start up
```

ブラウザで `http://localhost:80` にアクセスしてみます(`:80`部分は無くても動きます)。無事にページが見られたでしょうか？

### Container Registryへの登録

Dockerイメージに問題が無さそうであれば、Container Registryにイメージを上げてみます。複数のコマンドを実行するのが大変なので、今回はMakefileにまとめていますが、変数部分を埋めてシェルからpush-image部分の個別のコマンドを叩けば問題ありません。

```Makefile
GCP_PROJECT_ID = my-gcp-project
DOCKR_IMAGE_NAME = my-server

.PHONY: publish
publish:
	@ rm -rf ./public; \
	  hugo

.PHONY: push-image
push-image: publish
  @ gcloud auth login; \
    gcloud config set project $(GCP_PROJECT_ID); \
    gcloud auth configure-docker; \
    docker rmi gcr.io/$(GCP_PROJECT_ID)/$(DOCKER_IMAGE_NAME):latest; \
    docker build -t gcr.io/$(GCP_PROJECT_ID)/$(DOCKER_IMAGE_NAME):latest . ;\
    docker push gcr.io/$(GCP_PROJECT_ID)/$(DOCKER_IMAGE_NAME):latest
```

各コマンドのやっている内容は以下の通りです。
1. [Cloud SDK](https://cloud.google.com/sdk?hl=JA)に含まれる `gcloud`コマンドを利用して認証します。(ログイン画面が表示されます)
1. 対象のGCPプロジェクトを指定します 
1. Dockerを構成し、認証情報を`$HOME/.docker/config.json`に保存します
1. ローカルに古いイメージがあれば削除します
1. ローカルで新規イメージをビルドします
1. ローカルでビルドしたイメージをレジストリに登録します

コマンドをまとめて実行するには、`Makefile`を作成し上記の定義を書いた後、以下のコマンドを打ちます。
```
$ make push-image
```
ブラウザが起動しログインを促されるので、GCPプロジェクトに登録してあるアカウントで認証を完了します。 (アクセスのリクエストも出ますので許可してあげてください)
(ここで指定するアカウントには、GCPの`IAM`上でCloud RegistryとCloud Runの実行権限を事前付与しておいてください)

### Cloud Run への反映
Cloud Run への反映は次のようなコマンドで行います。先に登録したイメージを指定し、80番ポートを開けています。Cloud Runの実装はマネージド(他にGKE, Anthos等が実装として存在)を指定し、リージョンは東京を指定しています。

```Makefile
CLOUD_RUN_SERVICE = my-service

.PHONY: deploy-image
deploy-image: push-image
	@ gcloud beta run deploy $(CLOUD_RUN_SERVICE) \
    --image gcr.io/$(GCP_PROJECT_ID)/$(DOCKER_IMAGE_NAME):latest \
    --port 80 \
    --platform=managed \
    --region=asia-northeast1
```

その他細かいオプションが知りたい方は以下のコマンドを実行してみてください。
```bash
$ gcloud beta run deploy --help
```

実行すると暫く待たされますが、数十秒程度でデプロイが完了します。出力の最後に `Service URL`というのが出ますので、そこにアクセスするとサイトが表示されます。

```shell
Deploying container to Cloud Run service [my-service] in project [my-gcp-project] region [asia-northeast1]
✓ Deploying... Done.                                                                                                                  
  ✓ Creating Revision...                                                                                                              
  ✓ Routing traffic...                                                                                                                
Done.                                                                                                                                 
Service [my-service] revision [my-server-00011-pip] has been deployed and is serving 100 percent of traffic.
Service URL: https://my-service-xxxxxxxxxx-an.a.run.app
```
ここにアクセスすれば、クラウド上にアップロードしたサイトを見ることができます。これでHTTPS化も含めた公開はできていますが、自動生成されたURLは複雑です。そこで、これからは独自ドメインを割り当てる方法を見てゆきたいと思います。


## 独自ドメインの適用

前提として、ドメインを既に取得し、DNSサーバも保有しているとします。
自分の場合は、お名前.comでドメインを取得し、CloudDNSで DNSサーバを運用しています。

ここでは、取得したドメインが `my-domain.com` であり、`my-service.my-domain.com`でサイトを公開したいと仮定します  
最初に行うのは、ドメインの所有者であることの証明です。先ずは`gcloud`で以下のコマンドを叩きます

```
$ gcloud domains verify my-service.my-domain.com
```
`ウェブマスターセントラル`がブラウザ上で表示され、ドメイン所有の証明を促されます。

1. 最初にドメインの発行元として、プルダウンから「`Onamae.com`」を選択します。
2. 次に提示されたTXTレコードを自身のDNSサーバ上に登録します。今回の例では 
   1. Cloud DNS上のゾーン`my-domain.com` を開いて以下の値を入力し「作成」
   2. `レコードセットの追加`から新規レコードセットを追加
      1. DNS名に`my-service.my-domain.com`
      2. リソースレコードのタイプに`TXT`
      3. テキストデータにウェブマスターセントラルのページ上で指定された値 ("以下のTXTレコードを…"部分)
3. 登録が終わったら「確認」ボタンを押します。 

![](/posts/site/hugo/web-master-central.png)

![](/posts/site/hugo/cloud-dns.png)

| # | 設定名 | 設定値 |
| --- | --- | --- |
| 1 | DNS名 | `my-service.my-domain.com` |
| 2 | TTL | 5 |
| 3 | TTLユニット | 分 |
| 3 | テキストデータ | `ghs.googlehosted.com.` |

確認が終わったら、`Cloud DNS`上で確認に使った TXTレコードを削除し、代わりに同名の `CNAME`レコードを追加します。  
(同名のレコードを多重登録できないので、まずTXTレコードに認証し、次にそれを消してCNAMEレコードを登録し…という手順を踏む必要があります)
&nbsp;  
最後に、Cloud Run上にドメインとの連携を指示します。

```
$ gcloud beta run domain-mappings create --service my-service --domain my-service.my-domain.com --platform=managed --region=asia-northeast1
Creating......done.                                                                                                                   
Waiting for certificate provisioning. You must configure your DNS records for certificate issuance to begin.
```

すぐには反映されませんが、軽く外出して帰ってくる頃には証明書が展開され、`https://my-service.my-domain.com` でのアクセスが可能になります。

以上が Cloud Runによる Hugoサイトの構築でした。

注意点として、Container Registry上には以前に登録した歴代のイメージが登録されてゆきますので、定期的に古いイメージを削除して GCSの利用料金(Container Registryのイメージは内部的にGCSが利用されています)を抑えてあげてください。

下記の gcloudコマンドを実行すると、現在のタグ一覧(イメージ履歴に相当)が表示されます。latestの部分が 通常Cloud Runが参照しているイメージです。(下記テンプレートで強調した部分は自身の環境に合わせてください)  

> $ gcloud container images list-tags gcr.io/`my-gcp-project`/`my-service`

```shell
$ gcloud container images list-tags gcr.io/my-gcp-project/my-service

DIGEST        TAGS    TIMESTAMP
1e59ccdaa62e  latest  2020-12-12T14:58:46
55c60e5dd430          2020-12-12T13:45:09
2235780b3fds          2020-12-12T13:41:13
1c200a0d0ffa          2020-12-12T13:13:56
a3282f56e5ff          2020-12-12T13:12:00
0cdbadd252e9          2020-12-12T03:40:12
33092f01xxc2          2020-12-12T01:34:00
```

次は上記の DIGESTを指定しての削除です。この例では2番目に新しいイメージを削除しています。  
(下記テンプレートで強調した部分は自身の環境に合わせてください)  

> $ gcloud container images delete gcr.io/`my-gcp-project`/`my-service`@sha256:`55c60e5dd430`

```
$ gcloud container images delete gcr.io/my-gcp-project/my-service@sha256:55c60e5dd430

Digests:
- gcr.io/xxxxxxxxxxxxxxxxxxxxx
This operation will delete the tags and images identified by the 
digests above.

Do you want to continue (Y/n)?  y

Deleted [gcr.io/my-gcp-project/my-service@sha256:55c60e5dd430xxxxxxxxxxxxxxxxxxxxxxx].
```

### まとめ
今回は、Cloud Runを用いた Hugoサイトの構築を実施しました。
- Cloud LB x GCSの課題と CloudRunの適性
- Dockerfile作成と動作確認
- Container Registryへの登録
- Cloud Runへの反映
- 独自ドメインの適用

Cloud Runを用いた静的サイトの公開は、Cloud Runのコールドスタートの瞬間若干引っかかる時がありますが、概ね快適で運用コストも少なくなりそうです。このまま暫く様子をみてゆきたいと思います。お疲れさまでした。
