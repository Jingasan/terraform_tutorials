#============================================================
# 環境変数の定義
#============================================================
# プロジェクト名
variable "project_name" {
  type        = string
  description = "プロジェクト名（リソースの名前、タグ、説明文に利用される）"
  default     = "terraform-tutorials"
}
#============================================================
# AWS Account
#============================================================
# AWSのリージョン
variable "region" {
  type        = string
  description = "AWSのリージョン"
  default     = "ap-northeast-1"
}
# AWSアクセスキーのプロファイル
variable "profile" {
  type        = string
  description = "AWSアクセスキーのプロファイル"
  default     = "default"
}
#============================================================
# Route 53
#============================================================
# ドメイン
variable "route53_domain" {
  type        = string
  description = "ドメイン"
  default     = "example.com"
}
