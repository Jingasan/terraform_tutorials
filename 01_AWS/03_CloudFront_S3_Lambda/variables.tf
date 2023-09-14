#============================================================
# グローバル変数の定義（terraform.tfvarsの変数値を受け取る）
#============================================================

# AWSのリージョン
variable "region" {}
# AWSアクセスキーのプロファイル
variable "profile" {}
# バケット名
variable "bucket_name" {}
# ビルドしたLambda関数zipファイルのデプロイ先S3バケット名
variable "lambda_bucket_name" {}
# Lambda関数名
variable "lambda_name" {}
# IAMロール名
variable "iam_role_name" {}
# IAMポリシー名
variable "iam_policy_name" {}
# API Gateway名
variable "api_gateway_name" {}
# API URLステージ名
variable "stage_name" {}
# タグ名
variable "tag_name" {}
