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
# S3
#============================================================
# バケット名
variable "s3_bucket_name" {}
#============================================================
# WAF
#============================================================
# アクセスを許可するIPのリスト
variable "waf_allow_ips" {}
