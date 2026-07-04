provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# CloudFront 用の ACM 証明書は us-east-1 での発行が必須。
# 独自ドメインを付ける段階で使う（今は未使用だが用意しておく）。
provider "aws" {
  alias   = "us_east_1"
  region  = "us-east-1"
  profile = var.aws_profile
}
