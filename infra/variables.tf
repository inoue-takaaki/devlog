variable "project_name" {
  description = "リソース名の接頭辞"
  type        = string
  default     = "devlog"
}

variable "aws_region" {
  description = "S3 バケットを作るリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "aws_profile" {
  description = "ローカルの AWS プロファイル名。会社の default と分けるため個人用を指定する"
  type        = string
  default     = "personal"
}

variable "github_repo" {
  description = "OIDC でデプロイを許可する GitHub リポジトリ（owner/repo）"
  type        = string
  default     = "inoue-takaaki/devlog"
}
