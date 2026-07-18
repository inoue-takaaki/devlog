---
title: FF14募集アプリ開発 - ローカルにMySQLをDockerで立てる（DB環境編）
description: いよいよデータを保存する場所、データベースを用意します。自分のMacに直接インストールするのではなく、Docker で使い捨て・再現可能な MySQL 8.4 を立てる。compose.yaml を1行ずつ解説しながら、ポートを13306にした理由、データを消さない工夫、起動から接続確認までの手順をまとめます。連載第8回。
pubDate: 2026-07-18
author: taka
tags: ["ff14"]
---

連載8回目。前回まででコードの土台（ツールチェーンと共通パッケージ）が整いました。今回はいよいよ、**データを保存する場所＝データベース**を用意します。

とはいえ、まだアプリからDBを使うコードは書きません。今回やるのは「**ローカルに MySQL を、Docker で立てる**」ところまで。地味ですが、ここが土台になります。

## なぜ DB を Docker で立てるのか

MySQL を自分のMacに直接インストールする手もありますが、今回は **Docker** を使います。理由は3つ。

- **再現性**：`compose.yaml` という1つのファイルに設定を書いておけば、`docker compose up` 一発で誰でも同じDBが立つ。「自分の環境だけ動く」を避けられる。
- **隔離と使い捨て**：Macに直接入れると、バージョン管理や後片付けが面倒。Docker ならコンテナを**立てる/捨てる**だけで、Mac本体は汚れない。
- **本番と揃う**：このアプリの本番DBは AWS の RDS（MySQL 8.4）を想定しています。ローカルも同じ **MySQL 8.4** にすることで、「ローカルでは動くのに本番で挙動が違う」を減らせる。

## compose.yaml を1行ずつ読む

作った設定ファイルがこれです。1ブロックずつ意味を見ていきます。

```yaml
services:
  db:
    image: mysql:8.4
    container_name: ff14-db
    restart: unless-stopped
    ports:
      - '13306:3306'
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    command:
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_0900_ai_ci
    volumes:
      - db-data:/var/lib/mysql
    healthcheck:
      test:
        [
          'CMD-SHELL',
          'mysqladmin ping -h 127.0.0.1 -u root -p"$$MYSQL_ROOT_PASSWORD" --silent',
        ]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

volumes:
  db-data:
```

### `image: mysql:8.4`

使うイメージ（コンテナの素）です。`8.4` は MySQL の LTS（長期サポート版）で、本番の RDS と揃えています。ここでバージョンを固定しておくと、勝手に別バージョンに変わりません。

### `ports: - '13306:3306'`

`ホスト側:コンテナ側` の対応です。コンテナの中では MySQL は標準の **3306** で動きますが、それを **Macの 13306** に繋ぎます。

なぜ 3306 のままにしないかというと、**手元ではすでに別のローカルDBが標準の 3306 を使っていて、ぶつかるのを避けたい**から。ローカルのポートは自由に選べるので、衝突しない番号（13306）にずらしました。アプリからは `127.0.0.1:13306` で繋ぎます。

### `environment:`（初期設定）

MySQL イメージは、初回起動時にこの環境変数を見て、**root パスワード・データベース・アプリ用ユーザー**を自動で作ってくれます。

ここで `${MYSQL_ROOT_PASSWORD}` のように書いているのは、**値を直接ここに書かず、別ファイル（`.env`）から読む**ためです（後述）。

### `command:`（文字コード）

```yaml
command:
  - --character-set-server=utf8mb4
  - --collation-server=utf8mb4_0900_ai_ci
```

MySQL の起動オプションです。日本語（絵文字も）を正しく扱うために **utf8mb4** を明示しています。8.4 ではこれがデフォルトなのですが、「意図してそうしている」と分かるように書き残しました。

### `volumes: - db-data:/var/lib/mysql`

ここが**地味に一番大事**です。MySQL はデータを `/var/lib/mysql` に書きますが、これは**コンテナの中**。コンテナを消すとデータも消えてしまいます。

そこで、`db-data` という**名前付きボリューム**を作って、そこにデータを逃がしておきます。こうすると、**コンテナを作り直してもデータは残る**。最後の行の

```yaml
volumes:
  db-data:
```

がそのボリュームの宣言です。

### `healthcheck:`（本当に使えるか判定）

コンテナが「起動した」ことと、MySQL が「接続を受け付けられる」ことは別物です。MySQL は起動直後、内部の準備でしばらく接続を弾きます。

そこで、`mysqladmin ping` で定期的に生存確認し、OKになって初めて **healthy** とみなす、という設定を入れています。

```yaml
test:
  ['CMD-SHELL', 'mysqladmin ping -h 127.0.0.1 -u root -p"$$MYSQL_ROOT_PASSWORD" --silent']
```

ここで **`$$`** になっているのが小さなポイント。compose ファイルでは `$` が変数展開の記号なので、**コンテナの中のシェルにそのまま `$` を渡したい**ときは `$$` と二重にしてエスケープします。これで、パスワードを compose ファイルに埋め込まず、コンテナ内の環境変数を使って ping できます。

## 秘密は `.env`、共有するのは `.env.example`

`environment` が参照する実際の値は `.env` に書きます。ただし**パスワードを含む `.env` は Git にコミットしません**（`.gitignore` 済み）。代わりに、**中身を空にしたひな形** `.env.example` だけをリポジトリに置きます。

```bash
# .env.example（コミットする・ひな形）
MYSQL_ROOT_PASSWORD=rootpass
MYSQL_DATABASE=ff14
MYSQL_USER=ff14
MYSQL_PASSWORD=ff14pass
```

新しく環境を作る人は `cp .env.example .env` してから起動する、という流れです。「**動かすのに必要な設定の一覧**」は共有しつつ、「**実際の秘密の値**」は各自が持つ、という分け方ですね。

## 起動用のショートカット

毎回 `docker compose ...` と打つのは面倒なので、`package.json` に短いコマンドを用意しました。

```json
"db:up": "docker compose up -d",
"db:down": "docker compose down",
"db:logs": "docker compose logs -f db",
"db:reset": "docker compose down -v"
```

- `pnpm db:up`：起動（`-d` はバックグラウンド）
- `pnpm db:down`：停止（**データは残る**）
- `pnpm db:logs`：ログを追いかける
- `pnpm db:reset`：**ボリュームごと削除**（`-v`）。DBを完全にまっさらにしたいとき用

`db:down` と `db:reset` の違い（＝`-v` の有無でデータが残るか消えるか）は、最初に理解しておくと事故りません。

## 立ち上げて、確認する

実際に起動して、狙いどおりか確かめます。

```bash
pnpm db:up
```

コンテナが **healthy** になったら、中の MySQL を覗いてみます。

```
バージョン        → 8.4.10
データベース一覧  → ff14 がある
文字コード        → utf8mb4 / utf8mb4_0900_ai_ci
アプリ用ユーザー  → ff14 で ff14 DB に接続できる
```

環境変数で指定したとおり、`ff14` データベースと `ff14` ユーザーが自動で作られ、文字コードも utf8mb4 になっていました。最後に、アプリが繋ぐ **`127.0.0.1:13306`** にホスト側から接続できることも確認して、DBの準備は完了です。

## まとめ

- DB はMacに直接入れず、**Docker で立てる**：再現性・使い捨て・本番（RDS 8.4）と揃う
- `compose.yaml` に設定を宣言しておけば `pnpm db:up` 一発。ポートは手元の他のDBと衝突しない **13306** にした
- **データはコンテナではなく名前付きボリュームに逃がす**。だから作り直しても消えない（消したいときだけ `db:reset`）
- **秘密は `.env`（コミットしない）／ひな形 `.env.example`（コミットする）**で分ける
- healthcheck で「起動した」ではなく「**接続を受け付けられる**」を判定する

これで、データを保存する箱ができました。ただしまだ**中身（テーブル）は空っぽ**です。次回はいよいよ **Drizzle** を使って、設計してきた17個のエンティティを実際のテーブルとして定義します。前々回 `packages/shared` に置いた enum と、この MySQL が、そこでようやくつながります。
