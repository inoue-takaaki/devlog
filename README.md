# Side Quest

エンジニアの個人開発ログ。個人開発プロジェクト（FF14 パーティー募集アプリなど）や、
このブログ自体の構築を通じて得た技術的な学びを記録する Astro 製の技術ブログ。

## 技術

- [Astro](https://astro.build/) による静的サイト
- 記事は `src/content/blog/` の Markdown（ファイル名がそのまま URL スラッグ）
- 図は Mermaid（ビルド時に SVG へ変換）
- 著者は `src/data/authors.ts` で管理

## 開発

```sh
npm install
npm run dev      # http://localhost:4321
npm run build    # dist/ へ静的ビルド
npm run preview  # ビルド結果を確認
```

Node のバージョンは `.node-version`（nodenv）に従う。

## 記事の追加

`src/content/blog/<スラッグ>.md` を追加し、フロントマター（`title` / `description` /
`pubDate` / `author`）を書く。詳細は `.claude/skills/tech-blog-post` を参照。
