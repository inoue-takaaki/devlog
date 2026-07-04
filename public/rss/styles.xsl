<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" version="1.0" encoding="UTF-8" indent="yes" />

  <!-- RFC822形式（例: "Sat, 13 Jun 2026 00:00:00 GMT"）を日本語表記に変換 -->
  <xsl:template name="format-date">
    <xsl:param name="date" />
    <xsl:variable name="day" select="substring($date, 6, 2)" />
    <xsl:variable name="mon" select="substring($date, 9, 3)" />
    <xsl:variable name="year" select="substring($date, 13, 4)" />
    <xsl:variable name="month">
      <xsl:choose>
        <xsl:when test="$mon = 'Jan'">1</xsl:when>
        <xsl:when test="$mon = 'Feb'">2</xsl:when>
        <xsl:when test="$mon = 'Mar'">3</xsl:when>
        <xsl:when test="$mon = 'Apr'">4</xsl:when>
        <xsl:when test="$mon = 'May'">5</xsl:when>
        <xsl:when test="$mon = 'Jun'">6</xsl:when>
        <xsl:when test="$mon = 'Jul'">7</xsl:when>
        <xsl:when test="$mon = 'Aug'">8</xsl:when>
        <xsl:when test="$mon = 'Sep'">9</xsl:when>
        <xsl:when test="$mon = 'Oct'">10</xsl:when>
        <xsl:when test="$mon = 'Nov'">11</xsl:when>
        <xsl:when test="$mon = 'Dec'">12</xsl:when>
      </xsl:choose>
    </xsl:variable>
    <!-- 日の先頭ゼロを除去 -->
    <xsl:variable name="dayNum">
      <xsl:choose>
        <xsl:when test="substring($day, 1, 1) = '0'">
          <xsl:value-of select="substring($day, 2, 1)" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$day" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="concat($year, '年', $month, '月', $dayNum, '日')" />
  </xsl:template>

  <xsl:template match="/">
    <html lang="ja">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title><xsl:value-of select="/rss/channel/title" /> - RSSフィード</title>
        <style>
          :root {
            --primary: #00877a;
            --primary-dark: #006b60;
            --primary-light: #e6f3f1;
            --accent: #8bc34a;
            --text: #1f2933;
            --muted: #6b7280;
            --heading: #102a26;
            --border: #e3e8e6;
            --bg-subtle: #f5f9f7;
          }
          * { box-sizing: border-box; }
          body {
            margin: 0;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI",
              "Hiragino Sans", "Hiragino Kaku Gothic ProN", "Noto Sans JP",
              Meiryo, sans-serif;
            line-height: 1.8;
            color: var(--text);
            background: radial-gradient(1200px 400px at 100% -10%, var(--primary-light), transparent 60%) no-repeat, #fff;
            -webkit-font-smoothing: antialiased;
          }
          .wrap { max-width: 760px; margin: 0 auto; padding: 2.5rem 1.25rem 4rem; }
          .notice {
            background: var(--primary-light);
            border: 1px solid color-mix(in srgb, var(--primary) 25%, var(--border));
            border-radius: 12px;
            padding: 1.1rem 1.3rem;
            margin-bottom: 2.5rem;
            font-size: 0.95rem;
            color: var(--primary-dark);
          }
          .notice strong { color: var(--heading); }
          .notice code {
            background: #fff;
            border: 1px solid var(--border);
            border-radius: 6px;
            padding: 0.1em 0.45em;
            font-size: 0.9em;
            color: var(--primary-dark);
            word-break: break-all;
          }
          .eyebrow {
            margin: 0 0 0.4rem;
            font-size: 0.78rem;
            font-weight: 700;
            letter-spacing: 0.18em;
            color: var(--primary);
          }
          h1 { margin: 0 0 0.5rem; font-size: 2rem; color: var(--heading); }
          .desc { margin: 0 0 2.5rem; color: var(--muted); }
          .home {
            display: inline-block;
            margin-bottom: 2rem;
            font-size: 0.9rem;
            font-weight: 600;
            color: var(--primary-dark);
            text-decoration: none;
          }
          .home:hover { color: var(--primary); }
          .count {
            font-size: 0.85rem;
            color: var(--muted);
            margin-bottom: 1rem;
            font-weight: 600;
          }
          ul { list-style: none; margin: 0; padding: 0; display: grid; gap: 1rem; }
          li {
            border: 1px solid var(--border);
            border-radius: 12px;
            background: #fff;
            box-shadow: 0 1px 2px rgba(16, 42, 38, 0.06);
            transition: transform 0.15s ease, box-shadow 0.15s ease, border-color 0.15s ease;
          }
          li:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(16, 42, 38, 0.08);
            border-color: color-mix(in srgb, var(--primary) 35%, var(--border));
          }
          li a.item-link { display: block; padding: 1.3rem 1.5rem; text-decoration: none; color: inherit; }
          .item-date { font-size: 0.8rem; color: var(--primary); font-weight: 600; }
          .item-title { margin: 0.35rem 0 0.5rem; font-size: 1.2rem; color: var(--heading); }
          .item-desc { margin: 0; color: var(--muted); font-size: 0.93rem; }
          footer {
            margin-top: 3rem;
            padding-top: 1.5rem;
            border-top: 1px solid var(--border);
            color: var(--muted);
            font-size: 0.85rem;
            text-align: center;
          }
          footer a { color: var(--primary-dark); }
        </style>
      </head>
      <body>
        <div class="wrap">
          <a class="home" href="/">← ブログへ戻る</a>

          <p class="eyebrow">RSS FEED</p>
          <h1><xsl:value-of select="/rss/channel/title" /></h1>
          <p class="desc"><xsl:value-of select="/rss/channel/description" /></p>

          <div class="notice">
            <strong>これはRSSフィードです。</strong>
            新着記事を自動で受け取るための購読用ページです。
            お使いの<strong>RSSリーダー</strong>に、このページのURL
            <code><xsl:value-of select="/rss/channel/link" />rss.xml</code>
            を登録してください。記事を読むだけなら
            <a href="/">ブログのトップページ</a>からどうぞ。
          </div>

          <p class="count">
            最近の記事（<xsl:value-of select="count(/rss/channel/item)" />件）
          </p>
          <ul>
            <xsl:for-each select="/rss/channel/item">
              <li>
                <a class="item-link" href="{link}">
                  <div class="item-date">
                    <xsl:call-template name="format-date">
                      <xsl:with-param name="date" select="pubDate" />
                    </xsl:call-template>
                  </div>
                  <h2 class="item-title"><xsl:value-of select="title" /></h2>
                  <p class="item-desc"><xsl:value-of select="description" /></p>
                </a>
              </li>
            </xsl:for-each>
          </ul>

          <footer>
            <p>Powered by RSS ·
              <a href="/">Side Quest</a>
            </p>
          </footer>
        </div>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
