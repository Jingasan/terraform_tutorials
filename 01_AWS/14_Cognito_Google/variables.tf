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
# CloudFront
#============================================================
# 価格クラス (PriceClass_All/PriceClass_200/PriceClass_100)
# https://docs.aws.amazon.com/ja_jp/AmazonCloudFront/latest/DeveloperGuide/PriceClass.html
variable "cloudfront_price_class" {}
#============================================================
# Cognito
#============================================================
# OAuth2.0 APIによるGoogle認証のクライアントID 
variable "cognito_google_client_id" {}
# OAuth2.0 APIによるGoogle認証のクライアントシークレット
variable "cognito_google_client_secret" {}
