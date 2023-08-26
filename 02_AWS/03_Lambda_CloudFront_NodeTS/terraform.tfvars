### グローバル変数値の定義

# AWSのリージョン
region = "ap-northeast-1"
# AWSアクセスキーのプロファイル
profile = "default"
# ビルドしたLambda関数zipファイルのデプロイ先S3バケット名
lambda_bucket_name = "terraform-tutorial-lambda-bucket"
# Lambda関数名
lambda_name = "terraform_lambda"
# IAMロール名
iam_role_name = "terraform_lambda_role"
# IAMポリシー名
iam_policy_name = "terraform_lambda_policy"
# タグ名
tag_name = "Terraform検証用"