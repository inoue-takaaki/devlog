terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # 当面は tfstate をローカルに置く（*.tfstate は .gitignore 済みで公開リポに出さない）。
  # 慣れてきたら S3 + DynamoDB のリモートステートへ移行する。
  # backend "s3" {
  #   bucket         = "devlog-tfstate-xxxx"
  #   key            = "devlog/terraform.tfstate"
  #   region         = "ap-northeast-1"
  #   dynamodb_table = "devlog-tflock"
  # }
}
