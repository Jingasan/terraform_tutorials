#============================================================
# 環境変数の定義（terraform.tfvarsの変数値を受け取る）
#============================================================
# プロジェクト名（小文字英数字かハイフンのみ有効）
# プロジェクト毎に他のプロジェクトと被らないユニークな名前を指定すること
variable "project_name" {
  type        = string
  description = "プロジェクト名（リソースの名前、タグ、説明文に利用される）"
  default     = "default"
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
