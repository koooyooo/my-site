---
title: "Hugo"
date: 2020-11-28T13:28:21+09:00
draft: true
---

## Intro
[Hugo](https://gohugo.io/)でサイトを作成してみました。実際に作ってみるととても軽量なサイトになっているので驚きです。元々はWordPressでサイトを作成しようと考えていたのですが、[WordPress](https://ja.wordpress.com/)の場合コンテンツの管理にMySQLを利用するため、維持費の面で年に1万円前後かかってしまうというのがネックでした。

また、[はてなブログPro](https://hatenablog.com/guide/pro)等も検討し、こちらのほうがトータルでは安価で手軽なのですが、やはり自由度の面で一定の制限が掛かってしまいます (大抵の人には十分な自由度とは思いますが)

基本的には静的コンテンツを配信するだけなので、特段リッチな基盤は必要ありません。Webサーバ上にHTMLを置くだけでも良いわけです。特に、昨今は[Apache](https://httpd.apache.org/),[Nginx](https://nginx.org/en/)ベースの[Webサーバ](https://ja.wikipedia.org/wiki/Web%E3%82%B5%E3%83%BC%E3%83%90)を立てないでも配信する手段があります。[GitHubPages](https://docs.github.com/ja/free-pro-team@latest/github/working-with-github-pages/about-github-pages)を利用しても良いですし、[Amazon S3](https://aws.amazon.com/jp/s3/) や [Google Cloud Storage](https://cloud.google.com/storage/?hl=ja)といった Cloud上のストレージサービスに配信機能がありますので、その中にコンテンツを配備し設定を公開とするだけで安価に配信可能な訳です。

## Hugo
[Hugo](https://gohugo.io/)自体は、静的サイトジェネレーターと呼ばれるものです。静的サイトジェネレータの有名どころは [Site Generators](https://jamstack.org/generators/) で確認できますが、Hugoは [Golang](https://golang.org/)でこれを実現したものとなります。

### Markdown
Hugoではコンテンツ(文章)を[Markdown](https://ja.wikipedia.org/wiki/Markdown)として記述します。 平易な記法でリッチなコンテンツを表現できるため、最近では多くのBlogサービスもMarkdown記法に対応してきていますが、Hugoを始めとした静的サイトジェネレータはMarkdownを主たる記法としてコンテンツを生成しています。

### Static Site Generator

