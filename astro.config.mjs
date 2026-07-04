// @ts-check
import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';
import rehypeMermaid from 'rehype-mermaid';

// https://astro.build/config
export default defineConfig({
  // TODO: 個人ブログの配信先URLが確定したら差し替える
  site: 'https://example.com',
  integrations: [sitemap()],
  markdown: {
    // mermaid ブロックは構文ハイライトの対象から外し、rehype-mermaid に任せる
    syntaxHighlight: {
      type: 'shiki',
      excludeLangs: ['mermaid'],
    },
    // ```mermaid コードブロックをビルド時にSVGへ変換する
    rehypePlugins: [[rehypeMermaid, { strategy: 'inline-svg' }]],
  },
});
