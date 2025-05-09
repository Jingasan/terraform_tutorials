#============================================================
# 環境変数の定義（terraform.tfvarsの変数値を受け取る）
#============================================================
# プロジェクト名（小文字英数字かハイフンのみ有効）
# プロジェクト毎に他のプロジェクトと被らないユニークな名前を指定すること
variable "project_name" {
  type        = string
  description = "プロジェクト名（リソースの名前、タグ、説明文に利用される）"
  default     = "terraform-tutorials"
}
# プロジェクトのステージ名（例：dev/prod/test/個人名）
variable "project_stage" {
  type        = string
  description = "プロジェクトのステージ名（例：dev/prod/test/個人名）"
  default     = null
}
#============================================================
# AWS Provider
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
# CloudFront
#============================================================
# 価格クラス(PriceClass_All/PriceClass_200/PriceClass_100)
# PriceClass_Allは、すべてのリージョンを使用する。
# PriceClass_200は、北米、欧州、アフリカ、日本を含むアジア太平洋地域のリージョンを使用する。(利用推奨)
# PriceClass_100は、北米、欧州のリージョンを使用する。(日本が含まれない為、利用非推奨)
variable "cloudfront_price_class" {
  type        = string
  description = "価格クラス(PriceClass_All/PriceClass_200/PriceClass_100)"
  default     = "PriceClass_200"
}
#============================================================
# S3
#============================================================
# バケットの中にオブジェクトが入っていてもTerraformにバケットの削除を許可するかどうか(true:許可)
variable "s3_bucket_force_destroy" {
  type        = bool
  description = "バケットの中にオブジェクトが入っていてもTerraformにバケットの削除を許可するかどうか(true:許可)"
  default     = false
}
# 非最新バージョンの保持日数(日)：指定日数が経過したら非最新バージョンを削除する
variable "s3_lifecycle_noncurrent_version_expiration_days" {
  type        = number
  description = "非最新バージョンの保持日数(日)：指定日数が経過したら非最新バージョンを削除する"
  default     = 90
}
# 保持するバージョン数(個)：1~100
variable "s3_lifecycle_newer_noncurrent_versions" {
  type        = number
  description = "保持するバージョン数(個)：1~100"
  default     = 5
}
#============================================================
# Lambda
#============================================================
# 実行ランタイム（ex: nodejs, python, go, etc.）
variable "lambda_runtime" {
  type        = string
  description = "実行ランタイム（ex: nodejs, python, go, etc.）"
  default     = "nodejs22.x"
}
# CloudWatchにログを残す期間（日）
variable "lambda_cloudwatch_log_retention_in_days" {
  type        = number
  description = "CloudWatchにログを残す期間（日）"
  default     = 90
}
#============================================================
# API Gateway
#============================================================
# REST APIのステージ名（APIバージョン）（例：dev/prod/v1/v2）
variable "api_gateway_stage_name" {
  type        = string
  description = "API Gateway REST APIのステージ名（APIバージョン）（例：dev/prod/v1/v2）"
  default     = "dev"
}
