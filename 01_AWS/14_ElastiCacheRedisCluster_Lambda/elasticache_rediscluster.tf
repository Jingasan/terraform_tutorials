#============================================================
# ElastiCache for Redis
#============================================================

# Redisクラスターの作成
resource "aws_elasticache_replication_group" "redis" {
  # クラスターの名前
  replication_group_id = var.project_name
  # クラスターの説明文
  description = var.project_name
  # マルチAZの設定(true:有効/false:無効)
  multi_az_enabled = true
  # 自動フェイルオーバーの設定(true:有効/false:無効)(マルチAZの場合は必ずtrue)
  automatic_failover_enabled = true
  # エンジン(redisのみ有効)
  engine = var.elasticache_engine
  # エンジンのバージョン
  engine_version = var.elasticache_engine_version
  # ポート番号
  port = var.elasticache_port
  # パラメータグループ
  parameter_group_name = var.elasticache_parameter_group_name
  # ノードのタイプ(最小インスタンスの場合：cache.t2.micro)
  node_type = var.elasticache_node_type
  # シャード数(1-500個の値を指定)
  num_node_groups = var.elasticache_num_node_groups
  # レプリカ数(0-5個の値を指定)
  replicas_per_node_group = var.elasticache_replicas_per_node_group
  # データ階層化(ノードタイプr6gd使用時のみ有効)
  data_tiering_enabled = false
  # ネットワークタイプ
  network_type = "ipv4"
  # IPタイプの検出
  ip_discovery = "ipv4"
  # サブネットグループ名
  subnet_group_name = aws_elasticache_subnet_group.elasticache_redis.name
  # 保管中の暗号化
  at_rest_encryption_enabled = true
  # 転送中の暗号化
  transit_encryption_enabled = true
  # セキュリティグループID
  security_group_ids = [aws_security_group.elasticache_redis.id]
  # バックアップ保持期間(日)
  snapshot_retention_limit = var.elasticache_snapshot_retention_limit
  # バックアップ時間(UTC)
  snapshot_window = var.elasticache_snapshot_window
  # メンテナンス期間
  maintenance_window = var.elasticache_maintenance_window
  # マイナーバージョンの自動アップグレード
  auto_minor_version_upgrade = "true"
  # メンテナンス期間を待たずに変更を反映するか(true:反映する/false(default):反映しない)
  apply_immediately = true
  # タグ
  tags = {
    Name = var.project_name
  }
}



#============================================================
# ElastiCache Subnet Group
#============================================================

# サブネットグループの作成
resource "aws_elasticache_subnet_group" "elasticache_redis" {
  # サブネットグループ名
  name = "${var.project_name}-elasticache-redis"
  # サブネットグループの説明
  description = "ElastiCache Redis Subnet Group"
  # サブネットID
  subnet_ids = [for value in aws_subnet.private : value.id]
  # タグ
  tags = {
    Name = var.project_name
  }
}



#============================================================
# Security Group
#============================================================

# ElastiCache用のセキュリティグループ
resource "aws_security_group" "elasticache_redis" {
  # セキュリティグループ名
  name = "${var.project_name}-elasticache-redis-sg"
  # セキュリティグループの説明
  description = "ElastiCache Redis Security Group"
  # 適用先のVPC
  vpc_id = aws_vpc.default.id
  # タグ
  tags = {
    Name = var.project_name
  }
}

# ElastiCacheのセキュリティグループに割り当てるLambdaなどのアプリ用のインバウンドルール
resource "aws_security_group_rule" "elasticache_redis_ingress_app" {
  # 割り当て先のセキュリティグループID
  security_group_id = aws_security_group.elasticache_redis.id
  # typeをingressにすることでインバウンドルールになる
  type = "ingress"
  # 通信を許可するプロトコル/ポート番号/セキュリティグループ
  protocol                 = "tcp"
  from_port                = var.elasticache_port
  to_port                  = var.elasticache_port
  source_security_group_id = aws_security_group.elasticache_redis.id
  # 説明
  description = "${var.project_name} elasticache redis sgr from app access"
}
# RDSのセキュリティグループに割り当てるアウトバウンドルール
resource "aws_security_group_rule" "elasticache_redis_egress_all" {
  # 割り当て先のセキュリティグループID
  security_group_id = aws_security_group.elasticache_redis.id
  # typeをegressにすることでアウトバウンドルールになる
  type = "egress"
  # すべての通信を許可
  from_port   = 0
  to_port     = 0
  protocol    = "all"
  cidr_blocks = ["0.0.0.0/0"]
  # 説明
  description = "${var.project_name} elasticache redis sgr"
}

# 設定エンドポイント(ElastiCache RedisClusterの接続エンドポイント)
output "configuration_endpoint_address" {
  description = "Endpoint"
  value       = aws_elasticache_replication_group.redis.configuration_endpoint_address
}
