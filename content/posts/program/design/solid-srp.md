---
title: "Solid原則 - SRP"
date: 2021-02-02T00:49:47+09:00
draft: false
---

> 「これはね、Webも DBも メールも 何でもこなしている便利なサーバーなんだよ。」  
> 「それって下手に触ると全部止まってしまうってことかい？」

SRPはクラスの責務を限定することで、保守の範囲を限定化するための原則です。

<!-- <details> -->

冒頭の会話の例だと、最近ではコンテナを活用して環境を分離するのではないでしょうか。コンテナは一つのプロセスに責任を持つ存在です。一つの目的のために用意された環境なので、その目的に沿わない部品は気軽に変更・削除ができます。同じ考え方はプログラムにも適用可能です。プログラムはプロセスの構成要素ですから責務は更に細分化されます。

情報の保持に責任を持つモデル、画面とのやり取りを制御するコントローラ、一連のビジネスロジックに責任を持つサービス、または永続データのやり取りに責任を持つリポジトリ等様々なコンポーネントに分かれます。そうして責務を適切に細分化してゆくと、クラスが負う責務は1つになり、クラスを変更する理由も１つになります。

単一の責任しか負わないクラスは**コード量が減りシンプルに**なります。これが保守をする際の**理解容易性**に繋がります。そして余計な処理が紛れていないので**他の機能への副作用なく修正**できます。これが保守をする際の**安全性**に繋がります。

こうして単一の責任だけを持ったクラスが協調して全体を構築するべきだという原則が、**単一責任の原則**となります。

#### コードサンプル
(JVM系の言語のほうが得意ですが、勉強がてらGolangで書いてみました)

##### Before
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

##### After
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
