import { getCollection, type CollectionEntry } from "astro:content";
import { getTagLabel } from "../data/tags";

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

export interface TagCount {
  slug: string;
  label: string;
  count: number;
}

/** タグ(slug)ごとに集計。件数の多い順 → slug 順。表示名も付ける */
export function getTags(posts: Post[]): TagCount[] {
  const map = new Map<string, number>();
  for (const post of posts) {
    for (const slug of post.data.tags) {
      map.set(slug, (map.get(slug) ?? 0) + 1);
    }
  }
  return [...map.entries()]
    .map(([slug, count]) => ({ slug, label: getTagLabel(slug), count }))
    .sort((a, b) => b.count - a.count || a.slug.localeCompare(b.slug));
}

/** 指定タグ(slug)を含む記事を返す（渡された並び順を維持） */
export function getPostsByTag(posts: Post[], slug: string): Post[] {
  return posts.filter((post) => post.data.tags.includes(slug));
}

export const PAGE_SIZE = 10;

export function formatDate(d: Date): string {
  return d.toLocaleDateString("ja-JP", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });
}
