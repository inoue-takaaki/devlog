---
title: 記事に著者を紐付ける機能を実装する
description: 著者を一元管理する設定ファイルを用意し、記事の frontmatter から id で紐付けられるようにしました。表示名とアイコンをセットで管理し、一覧と記事ページに表示します。
pubDate: 2026-06-14
author: taka
tags: ["blog-dev"]
---

「誰が書いた記事か」が分かると、ブログの信頼感がぐっと増します。
このブログでは、著者を一元管理する仕組みを入れて、記事から id で紐付けられるようにしました。

## 著者の設定は1ファイルに集約

`src/data/authors.ts` が「ユーザー設定の場所」です。表示名・アイコン・ひとことをまとめて管理します。

```ts
import takaAvatar from "../assets/authors/taka.png";

export const authors = {
  taka: { name: "井上 嵩章", avatar: takaAvatar, bio: "エンジニア" },
  guest: { name: "ゲスト" },
} satisfies Record<string, Author>;

export const DEFAULT_AUTHOR_ID: AuthorId = "taka";
```

新しい人を増やすときは、ここにエントリを足すだけ。アイコンは `src/assets/authors/` に置いて
import するので、Astroの画像最適化もそのまま効きます。

## 記事との紐付け

スキーマに任意の `author` フィールドを足し、frontmatter で id を指定します。

```yaml
---
title: 記事タイトル
author: taka
---
```

指定がない記事は `getAuthor()` がデフォルト著者（`taka`）にフォールバックします。

```ts
export function getAuthor(id?: string): Author {
  if (id && id in authors) return authors[id as AuthorId];
  return authors[DEFAULT_AUTHOR_ID];
}
```

## 表示

`Avatar.astro` を作り、アイコン画像があれば `<img>`、なければ頭文字＋自動カラーの丸アバターに
フォールバックします。これを記事ページのバイライン（名前＋肩書き）と、一覧カードのフッター（小さいアバター＋名前）で使い回しています。

これで、設定は1ファイル・紐付けは1行で、著者の情報を破綻なく管理できるようになりました。
