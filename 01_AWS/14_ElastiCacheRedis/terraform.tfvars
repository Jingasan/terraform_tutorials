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
elasticache_engine_version = "7.1"
# ポート番号
elasticache_port = 6379
# パラメータグループ
elasticache_parameter_group_name = "default.redis7"
# ノードのタイプ(最小インスタンスの場合：cache.t2.micro)
elasticache_node_type = "cache.t2.micro"
# レプリカ数(0-5個の値を指定)
elasticache_replicas_per_node_group = 1
# バックアップ保持期間(日)
elasticache_snapshot_retention_limit = 1
# バックアップ時間(UTC)
elasticache_snapshot_window = "00:00-01:00"
# メンテナンス期間
elasticache_maintenance_window = "tue:03:00-tue:04:00"