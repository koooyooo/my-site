---
title: "Hugo"
date: 2020-11-28T13:28:21+09:00
draft: true
---

## Intro
[Hugo](https://gohugo.io/)でサイトを作成してみました。実際に作ってみるととても軽量なサイトになっているので驚きです。元々はWordPressでサイトを作成しようと考えていたのですが、[WordPress](https://ja.wordpress.com/)の場合コンテンツの管理にMySQLを利用するため、維持費の面で年に1万円前後かかってしまうというのがネックでした。

また、[はてなブログPro](https://hatenablog.com/guide/pro)等も検討し、こちらのほうがトータルでは安価で手軽なのですが、やはり自由度の面で一定の制限が掛かってしまいます (大抵の人には十分な自由度とは思いますが)

基本的には静的コンテンツを配信するだけなので、特段リッチな基盤は必要ありません。Webサーバ上にHTMLを置くだけでも良いわけです。特に、昨今はApache,NginxベースのWebサーバを立てないでも立てないでも配信する手段があります。[GitHubPages](https://docs.github.com/ja/free-pro-team@latest/github/working-with-github-pages/about-github-pages)を利用しても良いですし、[Amazon S3](https://aws.amazon.com/jp/s3/) や [Google Cloud Storage](https://cloud.google.com/storage/?hl=ja)といった Cloud上のストレージサービスに配信機能がありますので、その中にコンテンツを配備し設定を公開とするだけで安価に配信可能な訳です。

## Hugo
Hugo自体は、静的コンテンツの配信ツールと言われるものです。
