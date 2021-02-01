---
title: "Solid原則 - SRP"
date: 2021-02-02T00:49:47+09:00
weight: 200
draft: false
---

> 「これはね、Webも DBも メールも 何でもこなしている便利なサーバーなんだよ。」  
> 「それって下手に触ると全部止まってしまうってことかい？」

SRPはクラスの責務を限定することで、保守の範囲を限定化するための原則です。

---
## 概要
<!-- <details> -->

冒頭の会話の例だと、最近ではコンテナを活用して環境を分離するのではないでしょうか。コンテナは一つのプロセスに責任を持つ存在です。一つの目的のために用意された環境なので、その目的に沿わない部品は気軽に変更・削除ができます。同じ考え方はプログラムにも適用可能です。プログラムはプロセスの構成要素ですから責務は更に細分化されます。

細分化はアプリケーションが提供する**機能による細分化**、または1つの機能を実現するための**役割による細分化**、といった複数の切り口から行うことができます。機能による細分化は作るアプリケーションに依って異なりますが、役割による細分化の具体例としては、次のようになります。

- [情報系] メモリ上の情報保持に責任を持つ**モデル**
- [処理系-Biz] アクターとのユースケースを制御する**コントローラ**
- [処理系-Biz] アトミックなロジックに責任を持つ**サービス**
- [処理系-Biz] 永続データのやり取りに責任を持つ**リポジトリ**
- [処理系] ビジネスを意識しない汎用的な**ユーティリティ**

> *1) Biz = ビジネスロジック系

こうして責務を細分化してゆくと、クラスが負う責務は1つになり、責務が絞られるとそのクラスを変更する理由も１つに絞られます。つまり**単一の責任**しか負わないわけです。単一の責任しか負わないクラスでは次のような変化が起こります。

- **コード量減**と**ノイズ減**を実現することができ
  - 読み込む際の**理解容易性**が**向上**し
  - 更新する際の**副作用**が**低下**する
  
これが保守をする際の**安全性**に繋がります。この様に、単一の責任だけを持ったクラスが協調して全体を構築するべきだという原則が、**単一責任の原則**となります。

## 特徴

単一責任の原則の特徴は

### コードサンプル
(JVM系の言語のほうが得意ですが、勉強がてらGolangで書いてみました)

#### Before
```golang
// 複数の責務を負ってしまっている状態
type Server struct {
    HTMLs   []*web.HTML
    DBConn  *db.Conn
    Mails   []*mail.Mail
}
func (s Server) ServeWeb() error {
}
func (s Server) ServeDB() error {
}
func (s Server) ServeMail() error {
}
```

#### After
```golang
// 共通項としてのインターフェイス
type Container interface {
    Serve() error
}

// Web特化
type WebContainer struct {
    HTMLs  []*web.HTML
}
func (w WebContainer) Serve() error {
}

// DB特化
type DBContainer struct {
    DBConn  *db.Conn
}
func (d DBContainer) Serve() error {
}

// Mail特化
type MailContainer struct {
    Mails  []*mail.Mail
}
func (m MailContainer) Serve() error {
}

// 組み合わせて提供したい場合はこれも特化して用意
type Server struct {
    Containers []*Container
}
func (s Server) Serve() {
    for _, c := range s.Containers {
      go c.Serve()
    }
}
```
<!-- </details> -->
