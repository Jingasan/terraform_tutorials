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
# ElastiCache for Redis
#============================================================
# エンジン(redisのみ有効)
elasticache_engine = "redis"
# エンジンのバージョン
elasticache_engine_version = "7.0"
# ポート番号
elasticache_port = 6379
# パラメータグループ
elasticache_parameter_group_name = "default.redis7.cluster.on"
# ノードのタイプ(最小インスタンスの場合：cache.t2.micro)
elasticache_node_type = "cache.t2.micro"
# シャード数
elasticache_num_node_groups = 2
# レプリカ数
elasticache_replicas_per_node_group = 1
# バックアップ保持期間(日)
elasticache_snapshot_retention_limit = 1
# バックアップ時間(UTC)
elasticache_snapshot_window = "00:00-01:00"
# メンテナンス期間
elasticache_maintenance_window = "tue:03:00-tue:04:00"
#============================================================
# Lambda
#============================================================
# 実行ランタイム（ex: nodejs, python, go, etc.）
lambda_runtime = "nodejs18.x"
# Lambda関数のタイムアウト時間
lambda_timeout = 30
# CloudWatchにログを残す期間（日）
lambda_cloudwatch_log_retention_in_days = 30