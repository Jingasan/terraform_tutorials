#============================================================
# 環境変数の定義
#============================================================
# プロジェクト名
project_name = "terraform-tutorials"
#============================================================
# AWS Account
#============================================================
# AWSのリージョン
region = "ap-northeast-1"
# AWSアクセスキーのプロファイル
profile = "default"
#============================================================
# CloudFront
#============================================================
# 価格クラス (PriceClass_All/PriceClass_200/PriceClass_100)
# https://docs.aws.amazon.com/ja_jp/AmazonCloudFront/latest/DeveloperGuide/PriceClass.html
cloudfront_price_class = "PriceClass_200"
#============================================================
# Cognito
#============================================================
# OAuth2.0 APIによるGoogle認証のクライアントID 
cognito_google_client_id = "xxxxxxxxxxxxxxxxxxxx"
# OAuth2.0 APIによるGoogle認証のクライアントシークレット
cognito_google_client_secret = "xxxxxxxxxxxxxxxxxxxx"