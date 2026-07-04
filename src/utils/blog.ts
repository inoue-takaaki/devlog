import { getCollection, type CollectionEntry } from "astro:content";

export type Post = CollectionEntry<"blog">;

/** 公開日の新しい順にソートした全記事を返す */
export async function getSortedPosts(): Promise<Post[]> {
  const posts = await getCollection("blog");
  return posts.sort(
    (a, b) => b.data.pubDate.valueOf() - a.data.pubDate.valueOf()
  );
}

/** 記事を年ごとに集計（新しい年順、件数付き） */
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

export const PAGE_SIZE = 10;

export function formatDate(d: Date): string {
  return d.toLocaleDateString("ja-JP", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });
}
