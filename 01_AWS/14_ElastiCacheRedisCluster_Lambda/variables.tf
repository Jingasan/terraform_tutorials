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
# Network
#============================================================
# VPC CIDR
variable "vpc_cidr" {}
# パブリックサブネット CIDRS
variable "public_subnet_cidrs" {}
# プライベートサブネット CIDRS
variable "private_subnet_cidrs" {}
#============================================================
# ElastiCache for Redis
#============================================================
# エンジン(redisのみ有効)
variable "elasticache_engine" {}
# エンジンのバージョン
variable "elasticache_engine_version" {}
# ポート番号
variable "elasticache_port" {}
# パラメータグループ
variable "elasticache_parameter_group_name" {}
# ノードのタイプ(最小インスタンスの場合：cache.t2.micro)
variable "elasticache_node_type" {}
# シャード数
variable "elasticache_num_node_groups" {}
# レプリカ数
variable "elasticache_replicas_per_node_group" {}
# バックアップ保持期間(日)
variable "elasticache_snapshot_retention_limit" {}
# バックアップ時間(UTC)
variable "elasticache_snapshot_window" {}
# メンテナンス期間
variable "elasticache_maintenance_window" {}
#============================================================
# Lambda
#============================================================
# 実行ランタイム（ex: nodejs, python, go, etc.）
variable "lambda_runtime" {}
# Lambda関数のタイムアウト時間
variable "lambda_timeout" {}
# CloudWatchにログを残す期間（日）
variable "lambda_cloudwatch_log_retention_in_days" {}
