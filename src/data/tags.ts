export interface Tag {
  /** 表示名（一覧・タグページ・記事に表示される） */
  label: string;
}

/**
 * タグの表示名レジストリ。
 * 記事の frontmatter には slug（このオブジェクトのキー）を `tags: ["ff14"]` のように指定する。
 * 未登録の slug は自動でハイフンを空白に直した見出しにフォールバックするので、
 * まず記事に slug を書き、表示名を整えたくなったらここへ追記すればよい。
 */
export const tags = {
  // 連載・プロジェクト単位
  ff14: { label: "FF14アプリ" },
  "blog-dev": { label: "ブログ開発" },
  // 技術スタック（後で記事に付けるとき用に表示名だけ先に定義）
  typescript: { label: "TypeScript" },
  nuxt: { label: "Nuxt" },
  nestjs: { label: "NestJS" },
  drizzle: { label: "Drizzle" },
  mysql: { label: "MySQL" },
  astro: { label: "Astro" },
  terraform: { label: "Terraform" },
  aws: { label: "AWS" },
} satisfies Record<string, Tag>;

export type TagSlug = keyof typeof tags;

/** slug から表示名を得る。未登録の slug はハイフンを空白に直して整形しフォールバック */
export function getTagLabel(slug: string): string {
  if (slug in tags) return tags[slug as TagSlug].label;
  return slug
    .replace(/-/g, " ")
    .replace(/\b\w/g, (c) => c.toUpperCase());
}
