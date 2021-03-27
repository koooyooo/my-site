---
title: "Factory Method"
date: 2021-03-26T02:02:43+09:00
draft: false
---

## 目的
FactoryMethod はインスタンスの生成に関するパターンです。
このパターンの目的は、インターフェイスに対する実装の生成・代入局面を隠し、疎結合を完成させることです。

## 概要
インターフェイスを用いてポリモーフィズム（多様性）を実現したいとします。また、利用側にインターフェイスだけを見せることで疎結合も実現したいとします。こうすることで、多様な実装の切り替えに対応することができ保守性を高められるからです。さて、この時気をつけなければならないのが、ポリモーフィズム適用時の隙（仮称）です。

> #### ポリモーフィズム適用時の隙
> あるサスペンスドラマで犯人が怪人の仮面をかぶっていたとします。犯人はAさんかも知れない。しかしBさんかも知れない。AさんにもBさんにも第１の犯行が可能だ。そして難解なことに第２の犯行も可能だ。
> 
> ポリモーフィズムとは「**多様性**」です。**仕事を決めてやり方を決めない**「**インターフェイス**」によってその多様性を担保します。多様性はインターフェイスを満足させられる実装であれば、どれでも実現可能…という仕組みで担保します。この例で説明するならば、犯人はAさんでもあり得るしBさんでもあり得るのという部分です。そして「**疎結合**」というのは、利用者は何を使っているのかを感知していないという構造で担保します。この例で説明するならば、目撃者は仮面をつけて行った２つの犯行しか見ていないという部分です
> 
> しかし、**AさんかBさんの何れかが仮面を被るその瞬間を見られていたら？**
> 
> 多様性はいとも簡単に崩れ去ります。ですから犯人は仮面を被る瞬間を見られてはいけません。仮面を付けた状態で物陰から登場するのです。この、物陰の役割を果たす存在こそが Factory Method、物語や設計をミステリアスにさせるエッセンスです。
 
以上の例からもわかるように、Factoryと聞くと生成プロセスに注目してしまいがちですが、FactoryMethodの真の目的は生成物をインターフェイスの型で提供することで、その実体を隠しきることなのです。

例えば、良く見かける生成プロセスを隠しきれていないコードを提示します。このコードは生成のプロセスを完全に隠蔽してはいません。そのため当該スコープにおける多様性は担保出来ていません。これが Factoryを使わないコードの限界です。

```golang
var e tech.Engineer = &impl.Onda{}
e.Program()
e.Test()
e.Publish()
```
&nbsp;  
ではこのコードが問題であるかというと、一概にそうとも言えません。何故なら代入の瞬間以外はインターフェイスに依存していないコードであることは担保できているので、本当にポリモーフィズムが必要になったその後に、簡単にポリモーフィズムを完成させることができるからです。

> #### [余談] ポリモーフィズムとインターフェイス分離の原則
> 先の例に関してですが、名探偵が、様々な状況から推測して犯人を絞り込んでゆく様は、インターフェイスの責務を増やしてゆく過程に相当します。犯行日の深夜に動けた人、凶器を調達できた人、そして被害者の行動を知っていた人。最終的にインターフェイスを満足させ続けた人が犯人です。この様にして重すぎるインターフェイスの責務は実現クラスの枯渇を招きます。謎を解き明かしたい探偵の技術としては良いものですが、抽象化の力を振るいたい設計者として悪しきものです。この件に関する詳細は「**インターフェイス分離の原則**」で説明したいと思います

## 実現
次のシナリオでは、`"Hello"`という文字列を格納するため、Storageを生成しています。最初のテストケースでは factoryを用いてその実体を隠蔽できていますが、二番目のテストケースでは factoryを用いないため、その実体を隠しきれていません。この瞬間に**疎結合**という価値は失われてしまいます。

```
package factory_method_pattern

import (
	"testing"

	"github.com/stretchr/testify/assert"

	"github.com/koooyooo/go-design-pattern/factory_method/factory"
)

// FactoryMethodを適用した場合
// Storageの実体を知ることなく利用できる (疎結合)
func TestFactoryMethod(t *testing.T) {
	// Factory経由で実体を隠蔽
	s := factory.CreateStorage()
	err := s.Store([]byte("Hello"))
	assert.NoError(t, err)
}

// FactoryMethodを適用しない場合
// Storageの実体を知ってしまう (密結合)
func TestNonFactory(t *testing.T) {
	var s factory.Storage
	// 生成・代入プロセスで実体と密結合
	s = &factory.NoopStorage{}
	err := s.Store([]byte("Hello"))
	assert.NoError(t, err)
}
```
&nbsp;  
次に、Factoryの実装を示します。実装は別 packageに FactoryMethodを定義し、**Interfaceの型で値を返却**するだけです。この例では具象クラスをハードコードしていますが、設定ファイル上の状態を元に返却する実装を切り変えたり、同じく引数の値を元に返却する実装を切り替えたり…といった高機能な FactoryMethodを実現することも可能です。しかし、FactoryMethodの最大の価値は、実体の代入を隠蔽しきることなので、そこさえ守れれば簡易的な実装でも構わないのです。

```golang
package factory

func CreateStorage() Storage {
	// 何らかの具象を返却（例として diskStorageを選択）
	// 呼び出し元が具象を意識しないので、気づかれずに切り替えることが可能
	return &diskStorage{}
}
```

これだけだと、それほど価値があるようには見えませんが、様々な実装が控えているとするならば、そこを隠し切る価値も見えてくるのではないかと思います。

```golang
package factory

type (
	Storage interface {
		Store([]byte) error
	}
)

// S3実装
type s3Storage struct{}

func (s s3Storage) Store(data []byte) error {
	// TODO Implement this func
	return nil
}

// Disk実装
type diskStorage struct{}

func (s diskStorage) Store(data []byte) error {
	// TODO Implement this func
	return nil
}

// Memory実装
type memoryStorage struct{}

func (s memoryStorage) Store(data []byte) error {
	// TODO Implement this func
	return nil
}

// 無実装
type NoopStorage struct{}

func (s NoopStorage) Store(data []byte) error {
	// TODO Implement this func
	return nil
}

```
&nbsp;  

さて、デザインの利用状況には、言語的な環境の違いも影響します。FactoryMethodはその顕著な例で、Javaのクラスは一般的にコンストラクタで生成しますが、Golangの structは New関数で生成するケースも多いと思います。このNew関数が返す型が**Interface型**になっていたら？実はそれは立派な FactoryMethodです。

## デザイン例
他に FactoryMethodに関するデザインを挙げてみます。
- **Singleton**はインスタンスの生成こそしていませんが、利用者側が生成関数を通じてインスタンスを取得する点は類似しています
- **DIコンテナ**は Factoryの完成形と言えるべきものです。単純な隠蔽だけでなく、以下の価値も提供しています
  - AbstractFactoryとして依存関係ごとFactoryで提供
  - 依存性を注入することで、Factoryの存在すら隠蔽
  - 管理インスタンスは不要であれば再生成を控える（事実上のSingleton）


## まとめ
今回は、生成・適用の過程を見せないことで、ポリモーフィズムによる疎結合を完全なものにする Factory Methodを勉強しました。Singletonと同様、FactoryMethodはデザイン・パターンとして、基礎的で且つ原始的なものです。そのため、今日では DI等の上位互換を用いて課題解決される場合も少なくありません。

しかし、局所的な疎結合を簡易的に作り込む際は、FactoryMethodが活躍する局面です。軽量・重量の解決策を上手く使いこなして局面局面での最適解を導きたいですね。

それでは、FactoryMethodのあるプログラミングライフを楽しんでください！
