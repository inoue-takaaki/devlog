# CloudFront：S3 を OAC で参照し、HTTPS で配信する

resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "${var.project_name}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "rewrite" {
  name    = "${var.project_name}-rewrite-index"
  runtime = "cloudfront-js-2.0"
  comment = "ディレクトリURLを index.html に書き換える"
  publish = true
  code    = file("${path.module}/functions/rewrite-index.js")
}

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = var.project_name
  default_root_object = "index.html"
  price_class         = "PriceClass_200" # 日本を含むアジア・北米・欧州

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3-${aws_s3_bucket.site.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-${aws_s3_bucket.site.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    # AWS マネージドの CachingOptimized ポリシー
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.rewrite.arn
    }
  }

  # 存在しないパスは Astro の 404 ページを返す
  custom_error_response {
    error_code            = 403
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 10
  }
  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 10
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # 独自ドメインを付けるまでは CloudFront のデフォルト証明書を使う
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
