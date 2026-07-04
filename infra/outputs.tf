# apply 後、この値を GitHub リポジトリの Variables に登録する（下記 README 参照）

output "s3_bucket" {
  description = "GitHub Variables: S3_BUCKET"
  value       = aws_s3_bucket.site.id
}

output "cloudfront_distribution_id" {
  description = "GitHub Variables: CLOUDFRONT_DISTRIBUTION_ID"
  value       = aws_cloudfront_distribution.site.id
}

output "github_deploy_role_arn" {
  description = "GitHub Variables: AWS_DEPLOY_ROLE_ARN"
  value       = aws_iam_role.github_deploy.arn
}

output "aws_region" {
  description = "GitHub Variables: AWS_REGION"
  value       = var.aws_region
}

output "cloudfront_url" {
  description = "ブログの公開URL（独自ドメイン設定前）"
  value       = "https://${aws_cloudfront_distribution.site.domain_name}"
}
