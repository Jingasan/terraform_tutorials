#============================================================
# 環境変数の定義（terraform.tfvarsの変数値を受け取る）
#============================================================
# AWSのリージョン
variable "region" {}
# AWSアクセスキーのプロファイル
variable "profile" {}
# タグ名
variable "tag_name" {}
#============================================================
# Lambda
#============================================================
# ビルドしたLambda関数zipファイルのデプロイ先S3バケット名
variable "lambda_bucket_name" {}
# Lambda関数名
variable "lambda_name" {}
# 実行ランタイム（ex: nodejs, python, go, etc.）
variable "lambda_runtime" {}
# Lambda関数のタイムアウト時間
variable "lambda_timeout" {}
# CloudWatchにログを残す期間（日）
variable "lambda_cloudwatch_log_retention_in_days" {}
# IAMロール名
variable "lambda_iam_role_name" {}
# IAMポリシー名
variable "lambda_iam_policy_name" {}
