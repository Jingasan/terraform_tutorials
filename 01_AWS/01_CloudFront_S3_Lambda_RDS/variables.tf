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
# Network
#============================================================
# VPC CIDR
variable "vpc_cidr" {}
# パブリックサブネット CIDRS
variable "public_subnet_cidrs" {}
# プライベートサブネット CIDRS
variable "private_subnet_cidrs" {}
#============================================================
# RDS
#============================================================
# DBのタイプ
variable "rds_engine" {}
# DBのバージョン
variable "rds_engine_version" {}
# 初期DB名
variable "rds_dbname" {}
# DBポート番号
variable "rds_port" {}
# DBマスターユーザー名
variable "rds_username" {}
# DBマスターパスワード
variable "rds_password" {}
# インスタンスタイプ
variable "rds_instance_class" {}
# ストレージタイプ
variable "rds_storage_type" {}
# ストレージの割り当て量（GB）
variable "rds_allocated_storage" {}
# ストレージの自動スケーリングの有効化とスケーリング時の最大ストレージ量（GB）
variable "rds_max_allocated_storage" {}
# DBバックアップの保持期間（日）
variable "rds_backup_retention_period" {}
#============================================================
# RDS Proxy
#============================================================
# エンジンファミリー
variable "rds_proxy_engine_family" {}
# アプリケーションからののアイドル接続のタイムアウト（秒）（最小1分，最大8時間）
variable "rds_proxy_idle_client_timeout" {}
# DBの最大接続数に対して許容するRDS Proxyからの最大接続数（％）
variable "rds_proxy_max_connections_percent" {}
# DBの最大接続数に対して許容するRDS Proxyからの最大アイドル接続数（％）
variable "rds_proxy_max_idle_connections_percent" {}
# プールから借用したDB接続のタイムアウト時間（秒）
variable "rds_proxy_connection_borrow_timeout" {}
#============================================================
# Secrets Manager
#============================================================
# 削除後のシークレット保存期間（日）
variable "secret_manager_recovery_window_in_days" {}
#============================================================
# Lambda
#============================================================
# 実行ランタイム（ex: nodejs, python, go, etc.）
variable "lambda_runtime" {}
# Lambda関数のタイムアウト時間
variable "lambda_timeout" {}
# CloudWatchにログを残す期間（日）
variable "lambda_cloudwatch_log_retention_in_days" {}
#============================================================
# CloudFront
#============================================================
# S3オリジンID
variable "cloudfront_origin_id_s3" {}
# LambdaオリジンID
variable "cloudfront_origin_id_lambda" {}
# リバースプロキシ先のLambda関数URL
variable "cloudfront_path_pattern_lambda" {}
