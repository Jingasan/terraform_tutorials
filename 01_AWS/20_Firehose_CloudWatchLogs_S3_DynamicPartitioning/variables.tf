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
#============================================================
# S3
#============================================================
# Lambda関数のCloudWatchログのストレージクラス移行までの日数（日）：1以上の値を指定。指定日数が経過したらオブジェクトのクラスが移行する。
variable "s3_cloudwatch_log_lifecycle_transition_days" {
  type        = number
  description = "Lambda関数のCloudWatchログのストレージクラス移行までの日数（日）：1以上の値を指定。指定日数が経過したらオブジェクトのクラスが移行する。"
  default     = 1
}
# Lambda関数のCloudWatchログの保持日数（日）：1以上の値を指定。指定日数が経過したらオブジェクトが削除される。
variable "s3_cloudwatch_log_lifecycle_expiration_days" {
  type        = number
  description = "Lambda関数のCloudWatchログの保持日数（日）：1以上の値を指定。指定日数が経過したらオブジェクトが削除される。"
  default     = 90
}
#============================================================
# Data Firehose
#============================================================
# バッファリングサイズ（MB）の設定
#   動的パーティション分割無効時：（default: 5, 最小: 1, 最大: 128）
#   動的パーティション分割有効時：（default: 64, 最小: 64, 最大: 128）
# データを転送する際に指定されたサイズまでバッファリングしてから転送する。
# バッファサイズが大きいほど、コストが低くなり、レイテンシーが高くなる可能性がある。
# バッファサイズが小さいほど、配信が高速になり、コストが高くなり、レイテンシーが低くなる。
variable "firehose_buffering_size_mb" {
  type        = number
  description = "バッファリングサイズ（MB）の設定"
  default     = 128
}
# バッファリング間隔（秒）の設定
#   動的パーティション分割無効時：（default: 300, 最小: 60, 最大: 900）
#   動的パーティション分割有効時：（default: 300, 最小: 0, 最大: 900）
# データを転送する際に指定された秒数までバッファリングしてから転送する。
# 間隔が長いほど、データを収集する時間が長くなり、データのサイズが大きくなる場合がある。
# 間隔が短いほど、データが送信される頻度が高くなり、より短期サイクルでデータアクティビティを確認する場合のメリットが多くなる場合がある。
variable "firehose_buffering_interval_sec" {
  type        = number
  description = "バッファリング間隔（秒）の設定"
  default     = 60
}
