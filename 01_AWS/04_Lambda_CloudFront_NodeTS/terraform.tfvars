#============================================================
# 環境変数の定義
#============================================================
# AWSのリージョン
region = "ap-northeast-1"
# AWSアクセスキーのプロファイル
profile = "default"
# タグ名
tag_name = "Terraform検証用"
#============================================================
# Lambda
#============================================================
# ビルドしたLambda関数zipファイルのデプロイ先S3バケット名
lambda_bucket_name = "terraform-tutorial-lambda-bucket"
# Lambda関数名
lambda_name = "terraform_lambda"
# 実行ランタイム（ex: nodejs, python, go, etc.）
lambda_runtime = "nodejs18.x"
# Lambda関数のタイムアウト時間
lambda_timeout = 30
# CloudWatchにログを残す期間（日）
lambda_cloudwatch_log_retention_in_days = 30
# IAMロール名
lambda_iam_role_name = "terraform_lambda_role"
# IAMポリシー名
lambda_iam_policy_name = "terraform_lambda_policy"
