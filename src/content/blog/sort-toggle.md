---
title: 記事一覧の並び順を切り替える機能を実装する
description: 静的サイトのまま、新しい順／古い順をボタンで切り替えられるようにしました。追加ページを作らず、クライアントJSでDOMを並べ替えるシンプルな実装です。
pubDate: 2026-06-15
author: taka
---

並び順の切り替えは「一時的なUI操作」です。`/blog/asc` のような別URLを静的生成する方法もありますが、
ページ数が倍になるうえ、SEO的にも重複しがちです。そこでこのブログでは、数十行のクライアントJSで実現しました。

## 各カードに並べ替えキーを持たせる

`PostCard.astro` の `<li>` に、公開日時を `data-ts` 属性として埋め込みます。

```astro
---
const ts = post.data.pubDate.valueOf();
---
<li class="post-card" data-ts={ts}>
  ...
</li>
```

## ボタンでDOMを並べ替える

`PostListing.astro` の `<script>` で、トグルボタンを押すたびに `.post-list` の子要素を
`data-ts` で並べ替えて再追加します。

```ts
btn?.addEventListener("click", () => {
  const asc = btn.dataset.order === "desc";
  btn.dataset.order = asc ? "asc" : "desc";

  const items = Array.from(list.children) as HTMLElement[];
  items
    .sort((a, b) => {
      const ta = Number(a.dataset.ts);
      const tb = Number(b.dataset.ts);
      return asc ? ta - tb : tb - ta;
    })
    .forEach((el) => list.appendChild(el));
});
```

ラベルも「新しい順 ↓」「古い順 ↑」と切り替えて、現在の状態が分かるようにしています。

## トレードオフ

- ✅ 追加ページ不要・軽量・実装が短い
- ✅ サーバー不要、完全静的のまま動く
- ⚠️ 並べ替えはあくまで「現在表示中のページ内」が対象

ページをまたいだ全件の並べ替えが必要になったら、ビルド時の `getSortedPosts()` 側で
ソート順を変える方式に切り替えればOKです。今の記事数なら、まずはこのクライアントJSで十分です。
