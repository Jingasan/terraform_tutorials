#============================================================
# 環境変数の定義（terraform.tfvarsの変数値を受け取る）
#============================================================
# プロジェクト名
variable "project_name" {
  type        = string
  description = "プロジェクト名"
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
# Lambda
#============================================================
# 実行ランタイム（ex: nodejs, python, go, etc.）
variable "lambda_runtime" {
  type        = string
  description = "実行ランタイム（ex: nodejs, python, go, etc.）"
  default     = "nodejs22.x"
}
# Lambda関数のタイムアウト時間
variable "lambda_timeout" {
  type        = number
  description = "Lambda関数のタイムアウト時間"
  default     = 900
}
# CloudWatchにログを残す期間（日）
variable "lambda_cloudwatch_log_retention_in_days" {
  type        = number
  description = "CloudWatchにログを残す期間（日）"
  default     = 30
}
#============================================================
# API Gateway
#============================================================
# API URLステージ名
variable "apigateway_stage_name" {
  type        = string
  description = "API URLステージ名"
  default     = "dev"
}
