import type { ImageMetadata } from "astro";
import takaAvatar from "../assets/authors/taka.png";

export interface Author {
  /** 表示名 */
  name: string;
  /** アイコン画像（src/assets/authors/ に置いて import）。省略すると頭文字アバターになる */
  avatar?: ImageMetadata;
  /** 任意の肩書き・ひとこと */
  bio?: string;
}

/**
 * 著者の設定はここで行います。
 * キー（id）を記事の frontmatter に `author: <id>` として指定すると紐付きます。
 * 新しい著者を増やすときは、ここにエントリを追加するだけです。
 */
export const authors = {
  taka: {
    name: "井上 嵩章",
    avatar: takaAvatar,
    bio: "エンジニア",
  },
} satisfies Record<string, Author>;

export type AuthorId = keyof typeof authors;

/** 記事に author が指定されていない場合に使う著者 */
export const DEFAULT_AUTHOR_ID: AuthorId = "taka";

/** id から著者を取得。未知の id や未指定はデフォルト著者にフォールバック */
export function getAuthor(id?: string): Author {
  if (id && id in authors) return authors[id as AuthorId];
  return authors[DEFAULT_AUTHOR_ID];
}
