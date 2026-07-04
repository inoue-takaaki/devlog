# サイトの静的ファイルを置く S3 バケット（非公開。CloudFront 経由でのみ配信）

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "site" {
  bucket = "${var.project_name}-site-${random_id.suffix.hex}"
}

# パブリックアクセスは全面ブロック（CloudFront OAC からのみ読む）
resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront ディストリビューションからの GetObject のみ許可
data "aws_iam_policy_document" "site_bucket" {
  statement {
    sid       = "AllowCloudFrontRead"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.site.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.site_bucket.json
}
