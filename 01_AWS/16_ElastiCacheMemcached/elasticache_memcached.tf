#============================================================
# ElastiCache
#============================================================

# ElastiCacheクラスターの作成
resource "aws_elasticache_cluster" "memcached" {
  # クラスターID
  cluster_id = "${var.project_name}-${var.elasticache_engine}"
  # ElastiCacheのエンジン（valkey/redis/memcached）
  engine = var.elasticache_engine
  # ElastiCacheのエンジンのバージョン
  engine_version = var.elasticache_engine_version
  # ノードタイプ
  node_type = var.elasticache_node_type
  # ノード数
  num_cache_nodes = var.elasticache_num_cache_nodes
  # ノードとクラスターのランタイムプロパティを制御するパラメータグループの設定
  parameter_group_name = var.elasticache_parameter_group_name
  # Memcachedのポート番号
  port = var.elasticache_port
  # ノードを複数のAZに作成するかどうか（single-az(default):単一AZ／cross-az:複数AZ）
  # cross-azを指定する場合、num_cache_nodesの値は2以上である必要がある。
  az_mode = var.elasticache_az_mode
  # ノードを所属させるサブネットグループ名
  # 高可用性担保の為、ノード群を所属させるサブネットグループは
  # それぞれAZが異なる複数のプライベートサブネットで構成されること。
  subnet_group_name = aws_elasticache_subnet_group.memcached_subnet_group.name
  # ノード割り当て先のセキュリティグループID
  security_group_ids = [aws_security_group.elasticache_memcached.id]
  # ElastiCacheクラスターの設定値の変更を即時反映するか(true:即時反映する)
  # 即時反映しない場合は次回のメンテナンスウィンドウで反映される。
  apply_immediately = var.elasticache_apply_immediately
  # タグ
  tags = {
    Name              = "${var.project_name}-elasticache-memcached"
    ProjectName       = var.project_name
    ResourceCreatedBy = "terraform"
  }
}

# ElastiCacheサブネットグループ（ElastiCacheクラスターが利用するサブネットの集合）の作成
resource "aws_elasticache_subnet_group" "memcached_subnet_group" {
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
resource "aws_security_group" "elasticache_memcached" {
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
