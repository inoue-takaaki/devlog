# GitHub Actions が OIDC で assume するデプロイ用 IAM ロール（アクセスキーを保存しない）

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  # GitHub OIDC のサムプリント（AWS は既知IdPでは実質検証しないが、フィールドは必須）
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "github_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # 対象リポの main ブランチからの実行だけを許可
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_deploy" {
  name               = "${var.project_name}-github-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_assume.json
}

# デプロイに必要な最小権限：対象バケットへの同期と、対象ディストリビューションの無効化のみ
data "aws_iam_policy_document" "deploy" {
  statement {
    sid       = "S3List"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.site.arn]
  }

  statement {
    sid       = "S3Objects"
    actions   = ["s3:PutObject", "s3:DeleteObject", "s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]
  }

  statement {
    sid       = "CloudFrontInvalidation"
    actions   = ["cloudfront:CreateInvalidation"]
    resources = [aws_cloudfront_distribution.site.arn]
  }
}

resource "aws_iam_role_policy" "deploy" {
  name   = "${var.project_name}-deploy"
  role   = aws_iam_role.github_deploy.id
  policy = data.aws_iam_policy_document.deploy.json
}
