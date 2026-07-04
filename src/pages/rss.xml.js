import rss from "@astrojs/rss";
import { getCollection } from "astro:content";

export async function GET(context) {
  const posts = await getCollection("blog");

  return rss({
    title: "Side Quest",
    description: "エンジニアの個人開発ログ",
    site: context.site,
    // ブラウザで開いたとき見やすく表示するためのスタイルシート
    stylesheet: "/rss/styles.xsl",
    items: posts
      .sort((a, b) => b.data.pubDate.valueOf() - a.data.pubDate.valueOf())
      .map((post) => ({
        title: post.data.title,
        description: post.data.description,
        pubDate: post.data.pubDate,
        link: `/blog/${post.id}/`,
      })),
  });
}
