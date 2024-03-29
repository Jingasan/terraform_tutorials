#============================================================
# 環境変数の定義
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
# Route53
#============================================================
# Route53で事前に取得済みのドメイン名
variable "route53_domain" {}
