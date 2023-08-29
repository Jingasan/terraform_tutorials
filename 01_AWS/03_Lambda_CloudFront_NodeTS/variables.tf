### グローバル変数の定義（terraform.tfvarsの変数値を受け取る）

# AWSのリージョン
variable "region" {}
# AWSアクセスキーのプロファイル
variable "profile" {}
# ビルドしたLambda関数zipファイルのデプロイ先S3バケット名
variable "lambda_bucket_name" {}
# Lambda関数名
variable "lambda_name" {}
# IAMロール名
variable "iam_role_name" {}
# IAMポリシー名
variable "iam_policy_name" {}
# タグ名
variable "tag_name" {}
