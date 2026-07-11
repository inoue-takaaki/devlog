---
title: 年で記事を絞り込む機能を実装する
description: 記事から公開年を集計し、サイドバーの年別リンクから絞り込めるようにしました。Astroの getStaticPaths で年ごとのページを静的生成する実装を紹介します。
pubDate: 2026-06-16
author: taka
tags: ["blog-dev"]
---

記事が増えてくると、「2025年の記事だけ見たい」といった絞り込みが欲しくなります。
このブログは完全静的（SSRなし）ですが、Astroの `getStaticPaths` を使えば年ごとのページをビルド時に生成できます。

## 年の集計

まず全記事から公開年を集計します。`src/utils/blog.ts` にヘルパーを用意しました。

```ts
export function getYears(posts: Post[]): { year: number; count: number }[] {
  const map = new Map<number, number>();
  for (const post of posts) {
    const year = post.data.pubDate.getFullYear();
    map.set(year, (map.get(year) ?? 0) + 1);
  }
  return [...map.entries()]
    .map(([year, count]) => ({ year, count }))
    .sort((a, b) => b.year - a.year);
}
```

これで `[{ year: 2026, count: 12 }, { year: 2025, count: 4 }]` のような配列が得られ、
サイドバーに「2026年 (12)」のような件数付きリンクを出せます。

## 年ごとのページを生成

`src/pages/blog/year/[year]/[...page].astro` で、年ごとにページングしたページを生成します。

```ts
export const getStaticPaths = (async ({ paginate }) => {
  const posts = await getSortedPosts();
  return getYears(posts).flatMap(({ year }) => {
    const yearPosts = posts.filter(
      (post) => post.data.pubDate.getFullYear() === year
    );
    return paginate(yearPosts, { params: { year: String(year) }, pageSize: PAGE_SIZE });
  });
}) satisfies GetStaticPaths;
```

これで `/blog/year/2026/`、`/blog/year/2026/2/` のようなURLが自動で生成されます。

## ポイント

- 各年がURLを持つので、完全静的のままSEOに有利
- ページングと組み合わせられる（年内でも10件ごと）
- サイドバーの現在の年をハイライトすれば、どこを見ているか分かりやすい

絞り込みのUIは一覧の横に常駐させ、件数も一緒に見せることで回遊しやすくしています。
