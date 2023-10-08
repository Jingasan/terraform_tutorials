#============================================================
# 環境変数の定義
#============================================================
# プロジェクト名（小文字英数字かハイフンのみ有効）
project_name = "terraform-tutorials"
#============================================================
# AWS Account
#============================================================
# AWSのリージョン
region = "ap-northeast-1"
# AWSアクセスキーのプロファイル
profile = "default"
#============================================================
# Network
#============================================================
# VPC CIDR
vpc_cidr = "10.0.0.0/16"
# パブリックサブネット CIDRS
public_subnet_cidrs = {
  "a" = "10.0.0.0/24",
  "c" = "10.0.1.0/24"
}
# プライベートサブネット CIDRS
private_subnet_cidrs = {
  "a" = "10.0.2.0/24",
  "c" = "10.0.3.0/24"
}
#============================================================
# CloudFront
#============================================================
# 価格クラス (PriceClass_All/PriceClass_200/PriceClass_100)
# https://docs.aws.amazon.com/ja_jp/AmazonCloudFront/latest/DeveloperGuide/PriceClass.html
cloudfront_price_class = "PriceClass_200"
# S3オリジンID
cloudfront_origin_id_s3 = "S3"
# LambdaオリジンID
cloudfront_origin_id_lambda = "Lambda"
# リバースプロキシ先のLambda関数URL
cloudfront_path_pattern_lambda = "/api/*"
#============================================================
# Lambda
#============================================================
# 実行ランタイム（ex: nodejs, python, go, etc.）
lambda_runtime = "nodejs18.x"
# Lambda関数のタイムアウト時間
lambda_timeout = 30
# CloudWatchにログを残す期間（日）
lambda_cloudwatch_log_retention_in_days = 30
#============================================================
# RDS
#============================================================
# DBのタイプ
rds_engine = "postgres"
# DBのバージョン
rds_engine_version = "15.3"
# 初期DB名
rds_dbname = ""
# DBポート番号
rds_port = 5432
# DBマスターユーザー名
rds_username = "postgres"
# DBマスターパスワード
rds_password = "postgres"
# インスタンスタイプ
rds_instance_class = "db.t3.micro"
# ストレージタイプ
rds_storage_type = "gp2"
# ストレージの割り当て量（GB）
rds_allocated_storage = 20
# ストレージの自動スケーリングの有効化とスケーリング時の最大ストレージ量（GB）
rds_max_allocated_storage = 40
# DBバックアップの保持期間（日）
rds_backup_retention_period = 1
#============================================================
# RDS Proxy
#============================================================
# エンジンファミリー
rds_proxy_engine_family = "POSTGRESQL"
# アプリケーションからののアイドル接続のタイムアウト（秒）（最小1分，最大8時間）
rds_proxy_idle_client_timeout = 120
# DBの最大接続数に対して許容するRDS Proxyからの最大接続数（％）
rds_proxy_max_connections_percent = 100
# DBの最大接続数に対して許容するRDS Proxyからの最大アイドル接続数（％）
rds_proxy_max_idle_connections_percent = 50
# プールから借用したDB接続のタイムアウト時間（秒）（最大5分）
rds_proxy_connection_borrow_timeout = 120
#============================================================
# Secrets Manager
#============================================================
# 削除後のシークレット保存期間（日）
secret_manager_recovery_window_in_days = 0 # 保存しない
