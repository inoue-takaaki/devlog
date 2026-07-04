---
title: BitbucketとAWSで技術ブログのデプロイを自動化する（構想）
description: 記事をPRで追加し、承認・マージをトリガーにBitbucket PipelinesからAWSへ自動デプロイする運用構想です。AWS構成図、デプロイの流れ、必要な設定をまとめます。
pubDate: 2026-06-17
author: taka
---

> この記事は、このブログを将来的にどう運用していくかの**構想をまとめたもの**です。
> ここに書かれた設定や環境構築はまだ実施しておらず、これから整備していく予定です。

## 実現したい運用フロー

記事の追加から公開までを、次のような流れで回せるようにしたいと考えています。

1. 記事用のブランチを切り、Markdownを追加する
2. プルリクエスト（PR）を作成する
3. レビューで承認を得る
4. `main` ブランチへマージする
5. マージをトリガーに Bitbucket Pipelines が動き、AWSへ自動デプロイされる

```mermaid
flowchart LR
  A["記事ブランチで<br/>Markdownを追加"] --> B["PRを作成"]
  B --> C["レビュー / 承認"]
  C --> D["main へマージ"]
  D --> E["Bitbucket Pipelines<br/>が起動"]
  E --> F["ビルド & AWSへ<br/>デプロイ"]
  F --> G["公開"]
```

人手による作業は「記事を書く」「レビューする」だけで、ビルドとデプロイは自動化するのが狙いです。

## AWSの構成

静的サイトなので、**S3 + CloudFront** を中心としたシンプルな構成を想定しています。

```mermaid
flowchart TD
  Dev["開発者"] -->|PR / マージ| BB["Bitbucket<br/>リポジトリ"]
  BB --> Pipe["Bitbucket Pipelines<br/>（ビルド & デプロイ）"]
  Pipe -->|静的ファイルを同期| S3["S3バケット<br/>（dist/ の中身）"]
  Pipe -->|キャッシュ削除| CF["CloudFront<br/>（CDN）"]
  S3 --> CF
  CF --> R53["Route 53<br/>（DNS）"]
  ACM["ACM<br/>（SSL証明書）"] -.-> CF
  R53 --> User["読者のブラウザ"]
```

各要素の役割は次のとおりです。

| サービス | 役割 |
| :--- | :--- |
| **S3** | ビルド成果物（`dist/` の静的ファイル）の保管場所 |
| **CloudFront** | S3の前段に置くCDN。配信の高速化とHTTPS化 |
| **ACM** | CloudFront用のSSL証明書（HTTPS化に必須） |
| **Route 53** | ドメインのDNS。`example.com` 等をCloudFrontに向ける |
| **Bitbucket Pipelines** | ビルドとデプロイを実行するCI/CD |

CloudFrontを挟むことで、世界中どこからでも速く、かつHTTPSで配信できます。
S3を直接公開せず、CloudFront経由のみアクセスを許可するのが一般的な構成です。

## デプロイの流れ（マージ後）

`main` にマージされてから公開されるまでを、もう少し細かく見ると次のようになります。

```mermaid
sequenceDiagram
  participant Dev as 開発者
  participant BB as Bitbucket
  participant Pipe as Pipelines
  participant S3 as S3
  participant CF as CloudFront

  Dev->>BB: main へマージ
  BB->>Pipe: パイプライン起動
  Pipe->>Pipe: npm ci / playwright install
  Pipe->>Pipe: npm run build（dist/ 生成）
  Pipe->>S3: dist/ を同期（アップロード）
  Pipe->>CF: キャッシュを無効化（invalidation）
  CF-->>Dev: 新しい記事が公開される
```

ポイントは最後の **CloudFrontのキャッシュ無効化** です。
CloudFrontは配信を速くするためにファイルをキャッシュするので、
S3を更新しただけでは古い内容が表示され続けます。
デプロイの最後にキャッシュを消す（invalidation）ことで、最新の記事がすぐ反映されます。

## 必要な設定（これから整備する項目）

実現にあたって用意が必要なものを、AWS側・Bitbucket側に分けて整理します。

### AWS側

```mermaid
flowchart TD
  subgraph AWS
    A["1. S3バケット作成<br/>（静的ファイル用）"]
    B["2. CloudFront作成<br/>（オリジン = S3）"]
    C["3. ACMで証明書発行<br/>（独自ドメイン用）"]
    D["4. Route 53で<br/>ドメインをCloudFrontに向ける"]
    E["5. デプロイ用IAM<br/>（S3書き込み + CF無効化権限）"]
  end
  A --> B --> C --> D
  B --> E
```

- **S3バケット**: ビルド成果物の置き場所
- **CloudFront**: S3をオリジンに設定。デフォルトルートを `index.html` に
- **ACM**: 独自ドメインでHTTPS配信するための証明書（CloudFront用は**バージニア北部 `us-east-1`** で発行する点に注意）
- **Route 53**: ドメインのDNSレコードをCloudFrontに向ける
- **IAMユーザー（またはOIDC）**: Pipelinesがデプロイに使う認証情報。権限は「S3への書き込み」と「CloudFrontのinvalidation」に絞る

### Bitbucket側

Pipelinesで使う認証情報は、リポジトリの **Repository variables** に登録します
（コードには書かず、秘密情報として管理する）。

| 変数名 | 用途 |
| :--- | :--- |
| `AWS_ACCESS_KEY_ID` | デプロイ用IAMのアクセスキー |
| `AWS_SECRET_ACCESS_KEY` | 同シークレットキー（Secured指定） |
| `AWS_DEFAULT_REGION` | リージョン |
| `S3_BUCKET` | デプロイ先バケット名 |
| `CLOUDFRONT_DISTRIBUTION_ID` | キャッシュ無効化の対象 |

そのうえで、リポジトリ直下に `bitbucket-pipelines.yml` を置きます。
イメージとしては次のような内容になります。

```yaml
image: node:22

pipelines:
  # main へのマージ・push で本番デプロイ
  branches:
    main:
      - step:
          name: Build & Deploy
          deployment: production
          caches:
            - node
          script:
            - npm ci
            # Mermaidの図をSVG化するために必要
            - npx playwright install --with-deps chromium
            - npm run build
            # dist/ を S3 へ同期
            - pipe: atlassian/aws-s3-deploy:1.6.0
              variables:
                AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID
                AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY
                AWS_DEFAULT_REGION: $AWS_DEFAULT_REGION
                S3_BUCKET: $S3_BUCKET
                LOCAL_PATH: dist
                DELETE_FLAG: "true"
            # CloudFront のキャッシュを無効化
            - pipe: atlassian/aws-cloudfront-invalidate:0.6.0
              variables:
                AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID
                AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY
                AWS_DEFAULT_REGION: $AWS_DEFAULT_REGION
                DISTRIBUTION_ID: $CLOUDFRONT_DISTRIBUTION_ID

  # PR作成時はビルドが通るかだけ確認（デプロイはしない）
  pull-requests:
    "**":
      - step:
          name: Build check
          caches:
            - node
          script:
            - npm ci
            - npx playwright install --with-deps chromium
            - npm run build
```

`pull-requests` 側でビルドチェックだけ走らせておくと、
**マージ前に壊れた記事を検知**できるので安心です。

## ブランチ運用とレビュー

`main` を保護ブランチにして、直接pushを禁止し、必ずPR経由にします。

```mermaid
gitGraph
  commit id: "初期"
  branch add-article
  checkout add-article
  commit id: "記事を追加"
  commit id: "修正"
  checkout main
  merge add-article id: "承認後マージ"
```

- `main` への直接pushは禁止（保護ブランチ）
- 記事ごとにブランチを切ってPRを作成
- レビュー承認 + PRビルドの成功をマージ条件にする

これにより「レビューを通っていない記事が勝手に公開される」事故を防げます。

## 運用時の注意点

実際に運用する際に気をつけたい点をまとめておきます。

- **Playwrightのインストール**: このブログはMermaidをビルド時にSVG化するため、CI上でも `npx playwright install --with-deps chromium` が必要です。これを忘れるとビルドが失敗します。
- **CloudFrontのキャッシュ無効化**: invalidationには無料枠があり、それを超えると課金対象です。毎デプロイで `/*`（全体）を無効化すると枠を消費しやすいので、頻度や対象範囲は様子を見て調整します。
- **`site` の設定**: `astro.config.mjs` の `site` を本番ドメインに合わせること。これがRSS・sitemap・OGPのURLに反映されます。
- **認証情報の管理**: AWSのキーはコードに含めず、必ずBitbucketのSecured変数で管理します。権限も必要最小限（S3書き込み + CF無効化）に絞ります。

## まとめ

```mermaid
flowchart LR
  PR["PR作成"] --> Review["レビュー承認"]
  Review --> Merge["mainへマージ"]
  Merge --> Pipeline["Pipelines"]
  Pipeline --> S3["S3へ同期"]
  Pipeline --> CF["CloudFront無効化"]
  CF --> Live["公開"]
```

目指す姿は「**記事を書いてPRを出すだけで、承認・マージをきっかけに自動で公開される**」状態です。

- 配信基盤は S3 + CloudFront を中心としたシンプルな構成
- デプロイは Bitbucket Pipelines に集約し、ビルドからキャッシュ無効化まで自動化
- `main` は保護し、レビューを通った記事だけが公開される

繰り返しになりますが、これは**今後整備していくための構想**です。
実際の構築は、この記事の内容をベースに順次進めていく予定です。
