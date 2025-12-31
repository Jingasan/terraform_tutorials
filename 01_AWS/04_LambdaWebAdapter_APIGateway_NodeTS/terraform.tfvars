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
# Lambda
#============================================================
# 実行ランタイム（ex: nodejs, python, go, etc.）
lambda_runtime = "nodejs22.x"
# Lambda関数のメモリサイズ（MB）（最小128MB，最大10,240MB）
lambda_memory_size = 2048
# Lambda関数の一時ストレージサイズ（MB）（最小512MB、最大10,240MB）
lambda_ephemeral_storage_size = 512
# Lambda関数のアプリケーションのポート番号（Lambda Web AdapterのデフォルトはPORT=8080）
lambda_app_port = 3000
# Node.jsの実行環境（development/production）
lambda_node_env = "production"
# Lambda関数のタイムアウト時間
lambda_timeout = 30
# CloudWatchにログを残す期間（日）
lambda_cloudwatch_log_retention_in_days = 30
#============================================================
# API Gateway
#============================================================
# API URLステージ名
apigateway_stage_name = "dev"
