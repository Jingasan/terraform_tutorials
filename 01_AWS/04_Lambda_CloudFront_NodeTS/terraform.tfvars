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
# Lambda
#============================================================
# 実行ランタイム（ex: nodejs, python, go, etc.）
lambda_runtime = "nodejs18.x"
# Lambda関数のタイムアウト時間
lambda_timeout = 30
# CloudWatchにログを残す期間（日）
lambda_cloudwatch_log_retention_in_days = 30
