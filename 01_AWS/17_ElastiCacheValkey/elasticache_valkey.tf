#============================================================
# ElastiCache
#============================================================

# ElastiCacheクラスターの作成
resource "aws_elasticache_replication_group" "valkey" {
  # クラスターの名前
  replication_group_id = "${var.project_name}-${var.elasticache_engine}"
  # マルチAZの設定（true:有効/false:無効）
  multi_az_enabled = true
  # 自動フェイルオーバーの設定（true:有効/false:無効）（マルチAZの場合は必ずtrue）
  automatic_failover_enabled = true
  # エンジン（valkey/redis）
  engine = var.elasticache_engine
  # エンジンのバージョン
  engine_version = var.elasticache_engine_version
  # ポート番号
  port = var.elasticache_port
  # パラメータグループ
  parameter_group_name = var.elasticache_parameter_group_name
  # ノードのタイプ（最小インスタンスの場合：cache.t2.micro）
  node_type = var.elasticache_node_type
  # シャード数（1-500個の値を指定）
  num_node_groups = var.elasticache_min_capacity
  # レプリカ数（0-5個の値を指定）
  replicas_per_node_group = var.elasticache_replicas_per_node_group
  # データ階層化（ノードタイプr6gd使用時のみ有効）
  data_tiering_enabled = false
  # ネットワークタイプ
  network_type = "ipv4"
  # IPタイプの検出
  ip_discovery = "ipv4"
  # サブネットグループ名
  subnet_group_name = aws_elasticache_subnet_group.elasticache.name
  # 保管中の暗号化
  at_rest_encryption_enabled = true
  # 転送中の暗号化
  transit_encryption_enabled = true
  # Redisの接続パスワード（16-128文字で指定）
  auth_token = var.elasticache_auth_token
  # セキュリティグループID
  security_group_ids = [aws_security_group.elasticache.id]
  # バックアップ保持期間（日）
  snapshot_retention_limit = var.elasticache_snapshot_retention_limit
  # バックアップ時間（UTCの形式で指定）
  snapshot_window = var.elasticache_snapshot_window
  # メンテナンス期間（曜日:UTCの形式で指定）
  maintenance_window = var.elasticache_maintenance_window
  # マイナーバージョンの自動アップグレード
  auto_minor_version_upgrade = var.elasticache_auto_minor_version_upgrade
  # ElastiCacheクラスターの設定値の変更を即時反映するか（true:反映する/false(default):反映しない）
  # 即時反映しない場合は次回のメンテナンスウィンドウで反映される。
  apply_immediately = var.elasticache_apply_immediately
  # ログ出力設定
  # log_delivery_configuration {
  #   destination      = aws_cloudwatch_log_group.example.name
  #   destination_type = "cloudwatch-logs"
  #   log_format       = "json"
  #   log_type         = "slow-log"
  # }
  # log_delivery_configuration {
  #   destination      = aws_cloudwatch_log_group.example.name
  #   destination_type = "cloudwatch-logs"
  #   log_format       = "json"
  #   log_type         = "engine-log"
  # }
  # クラスターの説明文
  description = "${var.project_name}-${var.elasticache_engine}"
  # タグ
  tags = {
    Name              = "${var.project_name}-vpc"
    ProjectName       = var.project_name
    ResourceCreatedBy = "terraform"
  }
}

# オートスケーリング対象となるElastiCacheクラスターの設定
# ※ElastiCacheのオートスケーリングには、対象ノードタイプの制約がある。
resource "aws_appautoscaling_target" "valkey" {
  # 対象サービス名（ElastiCacheの場合はelasticache）
  service_namespace = "elasticache"
  # オートスケーリング対象のクラスターのリソースID（ElastiCacheの場合は、replication-group/<cluster-name>）
  resource_id = "replication-group/${aws_elasticache_replication_group.valkey.id}"
  # スケーリング対象（ElastiCacheの場合はelasticache:replication-group:NodeGroups）
  scalable_dimension = "elasticache:replication-group:NodeGroups"
  # 最大シャード数（1-500の値を指定）
  max_capacity = var.elasticache_max_capacity
  # 最小シャード数（1-500個の値を指定）
  min_capacity = var.elasticache_min_capacity
  # タグ
  tags = {
    Name              = "${var.project_name}-aurora-postgresql"
    ProjectName       = var.project_name
    ResourceCreatedBy = "terraform"
  }
}

# オートスケーリングのルール設定
resource "aws_appautoscaling_policy" "valkey_scaling_policy" {
  # ポリシー名
  name = "redis-scaling-policy"
  # ポリシータイプ
  policy_type = "TargetTrackingScaling"
  # 対象サービス名（ElastiCacheの場合はelasticache）
  service_namespace = aws_appautoscaling_target.valkey.service_namespace
  # オートスケーリング対象のクラスターのリソースID（ElastiCacheの場合は、replication-group/<cluster-name>）
  resource_id = aws_appautoscaling_target.valkey.resource_id
  # スケーリング対象（ElastiCacheの場合はelasticache:replication-group:NodeGroups）
  scalable_dimension = aws_appautoscaling_target.valkey.scalable_dimension
  # ポリシータイプがTargetTrackingScalingの場合のオートスケーリングルールの設定
  target_tracking_scaling_policy_configuration {
    # オートスケーリングのメトリクスの設定（AWSマネージドのメトリクスを利用する場合に使用）
    predefined_metric_specification {
      # メトリクスタイプの設定
      # ElastiCachePrimaryEngineCPUUtilization:シャードをCPU使用率でオートスケーリングさせる場合
      # ElastiCacheReplicaEngineCPUUtilization:レプリカノードをCPU使用率でオートスケーリングさせる場合
      predefined_metric_type = "ElastiCachePrimaryEngineCPUUtilization"
    }
    # メトリクスの目標値（最小:30%/最大:70%）（この値を超えたらスケールアウトする）
    target_value = 70.0
    # スケールイン直後の再スケーリングを防ぐクールダウン時間（秒）（default:5分）
    scale_in_cooldown = 300
    # スケールアウト直後の再スケーリングを防ぐクールダウン時間（秒）（default:5分）
    scale_out_cooldown = 300
  }
}

# ElastiCacheサブネットグループ（ElastiCacheクラスターが利用するサブネットの集合）の作成
resource "aws_elasticache_subnet_group" "elasticache" {
  # サブネットグループ名
  name = "${var.project_name}-elasticache-subnet-group"
  # グループの対象とするプライベートサブネットのID群
  subnet_ids = [for value in aws_subnet.private : value.id]
  # サブネットグループの説明
  description = "${var.project_name} ElastiCache Subnet Group for ${var.elasticache_engine}"
  # タグ
  tags = {
    Name              = "${var.project_name}-elasticache-memcached-sg"
    ProjectName       = var.project_name
    ResourceCreatedBy = "terraform"

  }
}



#============================================================
# Security Group
#============================================================

# ElastiCache用のセキュリティグループ
resource "aws_security_group" "elasticache" {
  # セキュリティグループ名
  name = "${var.project_name}-${var.elasticache_engine}-sg"
  # 適用先のVPC
  vpc_id = aws_vpc.main.id
  # インバウントルールの設定（外部からこのセキュリティグループに所属するリソースへのアクセス許可設定）
  ingress {
    # 許可する開始ポート番号
    from_port = var.elasticache_port
    # 許可する終了ポート番号
    to_port = var.elasticache_port
    # 使用するプロトコル（tcpはPostgreSQLの通信プロトコル）
    protocol = "tcp"
    # アクセスを許可する送信元IPアドレスの範囲
    # このVPC内のすべてのIPアドレスを指定することで、Lambdaなどのすべてのリソースからアクセスを許可する。
    cidr_blocks = [var.vpc_cidr]
  }
  # アウトバウンドルールの設定（このセキュリティグループに所属するリソースから外部へのアクセス許可設定）
  egress {
    # 許可する開始ポート番号（0はすべてのポート番号を許可）
    from_port = 0
    # 許可する終了ポート番号（0はすべてのポート番号を許可）
    to_port = 0
    # 使用するプロトコル（-1はすべてのプロトコルを許可）
    protocol = "-1"
    # アクセスを許可する送信先のIPアドレスの範囲
    # 0.0.0.0/0を指定することで、インターネット上のすべてのIPアドレスへのアクセスを許可する。
    cidr_blocks = ["0.0.0.0/0"]
  }
  # セキュリティグループの説明
  description = "${var.project_name} ElastiCache Security Group for ${var.elasticache_engine}"
  # タグ
  tags = {
    Name              = "${var.project_name}-elasticache-memcached-sg"
    ProjectName       = var.project_name
    ResourceCreatedBy = "terraform"
  }
}
