#============================================================
# 環境変数の定義（terraform.tfvarsの変数値を受け取る）
#============================================================
# プロジェクト名
variable "project_name" {}
#============================================================
# AWS Account
#============================================================
# AWSのリージョン
variable "region" {}
# AWSアクセスキーのプロファイル
variable "profile" {}
#============================================================
# Lambda
#============================================================
# 実行ランタイム（ex: nodejs, python, go, etc.）
variable "lambda_runtime" {}
# Lambda関数のメモリサイズ（MB）（最小128MB，最大10,240MB）
variable "lambda_memory_size" {}
# Lambda関数の一時ストレージサイズ（MB）（最小512MB、最大10,240MB）
variable "lambda_ephemeral_storage_size" {}
# Lambda関数のアプリケーションのポート番号（Lambda Web AdapterのデフォルトはPORT=8080）
variable "lambda_app_port" {}
# Node.jsの実行環境（development/production）
variable "lambda_node_env" {}
# Lambda関数のタイムアウト時間
variable "lambda_timeout" {}
# CloudWatchにログを残す期間（日）
variable "lambda_cloudwatch_log_retention_in_days" {}
#============================================================
# API Gateway
#============================================================
# API URLステージ名
variable "apigateway_stage_name" {}
