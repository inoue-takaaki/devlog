---
name: tech-blog-post
description: >
  この Astro 技術ブログに記事を書く・更新するときに使う（記事は src/content/blog に置く）。
  「ブログ記事を追加したい」「進捗を記事にまとめたい」「下書きを書いて」等のとき、たとえ
  "Astro" や "Markdown" と明示されなくても使う。フロントマターのスキーマ、著者(author)の
  紐付け、図は Mermaid か画像（SVG/PNG）で描くというこのブログの流儀、画像の置き場所、
  本番ビルドでの検証までをカバーする。README や
  ドキュメント等の記事以外の Markdown、レイアウト/コンポーネント/設定の編集には使わない。
compatibility: この Astro 技術ブログのリポジトリ。Node（.node-version 参照）と pnpm/npm が必要。
metadata:
  author: taka
  repo: Astro/devlog
---

# 技術ブログ記事の書き方

このリポジトリは Astro の静的ブログ。記事は Markdown ファイルで、Astro がビルド時にページへ
変換する。既存記事の流儀に合わせ、ビルドが通る形で書くこと。

## 記事の置き場所

- `src/content/blog/` に Markdown ファイルを追加する。
- **ファイル名がそのまま URL スラッグになる**: `src/content/blog/my-post.md` → `/blog/my-post`。
- スラッグは短い英小文字＋ハイフン（例: `ff14-party-finder-kickoff.md`）。

## フロントマター（必須）

スキーマは `src/content.config.ts` で定義されている。全記事にこのブロックが必要:

```md
---
title: 記事のタイトル
description: 一覧・SEO・OGP に使われる1〜2文の概要
pubDate: 2026-07-04
author: taka
---
```

- `title`（文字列・必須）
- `description`（文字列・必須）— 一覧やメタタグに表示される
- `pubDate`（日付・必須）— `YYYY-MM-DD`
- `author`（文字列・任意）— `src/data/authors.ts` の **id**（例: `taka`）。省略時はデフォルト
  著者にフォールバックする。新しい著者を使うときは先に `src/data/authors.ts` に追加する。
  勝手な id を書かない。

## 図は Mermaid か画像で描く

図は **Mermaid か画像（SVG/PNG）**のどちらでもよい。伝わりやすい方を選ぶ。

- **Mermaid** が向くもの: 構成図・フロー・シーケンス・ER図・状態遷移など。ビルド時に SVG へ
  変換され、外部アセット不要・差分管理しやすい。まず Mermaid で描けないか考えると楽なことが多い。
- **画像** が向くもの: 画面のワイヤーフレーム/モックアップ、リッチな図解、スクリーンショットなど、
  Mermaid では表現しづらいもの。SVG を手で書いて置いても、PNG を置いてもよい（置き場所は下記）。

Mermaid の例:

````md
```mermaid
flowchart LR
  A["入力"] --> B["処理"] --> C["出力"]
```
````

コードのフェンス、表、短いインラインコードもよく使う。選択肢の比較には表を使うと分かりやすい。

## 画像（SVG / PNG）

画面モックアップやスクリーンショット等、画像で見せたいとき:

| ファイルの置き場所 | 参照の書き方 | 最適化 |
| :--- | :--- | :--- |
| `src/assets/` | `![代替テキスト](../../assets/foo.png)` | される（ラスタ画像は推奨） |
| `public/` | `/images/foo.svg` | されない（手書き SVG はこちらが確実） |

ラスタ画像（PNG など）は `src/assets/` に置いて Astro に最適化させる。**手書きの SVG 図解は
`public/images/` に置いて絶対パス `/images/foo.svg` で参照する**のが確実（画像最適化を通さず
そのまま表示される）。alt テキストは必ず付ける。

## 執筆の手順

1. `src/content/blog/<スラッグ>.md` を作り、上記フロントマターを書く。
2. 本文を Markdown で書く。既存記事の構成に合わせる: 短い導入 → `##` セクション → 要所に
   Mermaid 図や表 → 末尾に `## まとめ`。
3. 文体は既存記事（`deploy-pipeline.md`, `astro-blog-setup.md`）に合わせる: 説明的な日本語、
   具体的、図で見せる。
4. **ビルドで検証する**（検証ループ）:
   ```sh
   npm run build
   ```
   - ビルドがフロントマターをスキーマ検証し、Mermaid を SVG へ変換する。失敗したらエラーを
     読み、直して、通るまで再ビルドする。
   - 生成物に新しいルート（`/blog/<スラッグ>/index.html`）が出ているか確認する。

## Gotchas（つまずきポイント）

- **フロントマターはビルド時にスキーマ検証される。** 項目の欠落や型違い（例: `pubDate` が
  日付でない）でビルドが失敗する。`src/content.config.ts` に合わせること。
- **Mermaid → SVG 変換にはヘッドレスブラウザ（Playwright/Chromium）を使う。** ローカルは
  `npm install` 後にそのまま動くが、CI では `npm run build` の前に
  `npx playwright install --with-deps chromium` が必要。忘れるとビルドが落ちる。
- **`author` は `src/data/authors.ts` に存在する id であること。** 未知の id は黙ってデフォルト
  著者にフォールバックする。新規なら先に id を追加する。
- **Node のバージョンはこのリポの `.node-version` で固定**。グローバルの別バージョンに頼らない。
- 図に生の HTML を書かない。図は Mermaid か画像ファイル（SVG/PNG）で表現する。
