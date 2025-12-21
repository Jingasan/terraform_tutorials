#============================================================
# Aurora
#============================================================

# Auroraクラスターの作成
resource "aws_rds_cluster" "aurora_postgresql" {
  # クラスター識別子
  cluster_identifier = "${var.project_name}-${var.aurora_engine}"
  # Aurora DBのエンジン（aurora-mysql/aurora-postgresql）
  engine = var.aurora_engine
  # Aurora DBのエンジンのバージョン
  engine_version = var.aurora_engine_version
  # Aurora DBのエンジンモード（parallelquery/provisioned/serverless）（ここでのserverlessはv1である為、v2を利用する場合はprovisionedを指定する）
  engine_mode = var.aurora_engine_mode
  # DBポート番号
  port = var.aurora_port
  # Aurora DBの初期DB名
  database_name = var.aurora_database_name
  # Aurora Serverless v2のスケーリング設定
  serverlessv2_scaling_configuration {
    # 最小ACU（0-256から0.5刻みで指定可能, 2.0GiB/ACU）
    min_capacity = var.aurora_min_acu
    # 最大ACU（1-256から0.5刻みで指定可能, 2.0GiB/ACU）
    max_capacity = var.aurora_max_acu
  }
  # Auroraインスタンスを所属させるサブネットグループ名
  # 高可用性担保の為、Auroraのインスタンス群を所属させるサブネットグループは
  # それぞれAZが異なる複数のプライベートサブネットで構成されること。
  db_subnet_group_name = aws_db_subnet_group.aurora.name
  # Aurora DB割り当て先のセキュリティグループID
  vpc_security_group_ids = [aws_security_group.aurora.id]
  # Aurora DBのマスターユーザー名
  master_username = var.aurora_master_username
  # Aurora DBのマスターパスワード
  master_password = var.aurora_master_password
  # Aurora DBのストレージ暗号化（true:暗号化する）
  storage_encrypted = true
  # CloudWatch Logsに出力するログの種類（指定しない場合は出力しない）
  # Aurora PostgreSQLの場合はpostgresql（PostgreSQLの一般ログを出力する）を指定可能。
  # （別途、PostgreSQL側でlog_statementなどのログ出力設定が必要だが、パラメータグループでも設定可能。）
  # 尚、ログの出力過多はCloudWatch Logsのコスト増大の原因となる為、出力するログ種類の選定やキャッシュサーバー導入などの検討が必要。
  enabled_cloudwatch_logs_exports = var.aurora_enabled_cloudwatch_logs_exports
  # パラメータグループの設定
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.custom_aurora_postgresql.name
  # Aurora DBのメンテナンスを実施する時間帯（曜日+UTC時刻）
  preferred_maintenance_window = var.aurora_preferred_maintenance_window
  # Aurora DBのバックアップ保持期間（日）
  backup_retention_period = var.aurora_backup_retention_period
  # Aurora DBのバックアップを実施する時間帯（UTC時刻）
  preferred_backup_window = var.aurora_preferred_backup_window
  # Auroraクラスターを削除時のバックアップ作成をスキップするかどうか（true:バックアップを作らずに削除する）
  skip_final_snapshot = var.aurora_skip_final_snapshot
  # 削除保護(true:DBクラスターを削除できなくする（defaultはfalse）)
  # クラスターの削除保護が有効な状態で削除したい場合、まずクラスターの削除保護を解除すること。
  deletion_protection = var.aurora_deletion_protection
  # エンジンのメジャーバージョンアップを許可するか（false:許可しない（default））
  allow_major_version_upgrade = false
  # Auroraクラスターの設定値の変更を即時反映するか(true:即時反映する)
  # 即時反映しない場合は次回のメンテナンスウィンドウで反映される。
  apply_immediately = var.aurora_apply_immediately
  # タグ
  tags = {
    Name              = "${var.project_name}-aurora-postgresql"
    ProjectName       = var.project_name
    ResourceCreatedBy = "terraform"
  }
}

# Auroraクラスターのインスタンスの設定
resource "aws_rds_cluster_instance" "aurora_instances" {
  # 初期インスタンス数
  count = var.aurora_min_capacity
  # インスタンス識別子
  identifier = "${var.project_name}-reader-instance-${count.index + 1}"
  # インスタンス割り当て先のクラスター識別子
  cluster_identifier = aws_rds_cluster.aurora_postgresql.id
  # Aurora DBのエンジン（aurora-mysql/aurora-postgresql）
  engine = aws_rds_cluster.aurora_postgresql.engine
  # Aurora DBのエンジンのバージョン
  engine_version = aws_rds_cluster.aurora_postgresql.engine_version
  # DBインスタンスタイプ
  instance_class = var.aurora_instance_class
  # DBインスタンスにインターネット経由のアクセスを許可するか（セキュリティ上、必ずfalseにすること）（default: false）
  # true: 許可。インスタンスにパブリックIPが割り当てられる。インスタンスがパブリックサブネット上にある場合に設定。
  # false: 拒否。VPC内からのみアクセスを許可。インスタンスがプライベートサブネット上にある場合に設定。
  publicly_accessible = false
  # DBインスタンスの設定値の変更を即時反映するか（true:反映する/false(default):反映しない）
  # 即時反映しない場合は次回のメンテナンスウィンドウで反映される。
  apply_immediately = var.aurora_apply_immediately
  # タグ
  tags = {
    Name              = "${var.project_name}-aurora-postgresql-instance-${count.index + 1}"
    ProjectName       = var.project_name
    ResourceCreatedBy = "terraform"
  }
}

# クラスターパラメータグループ
resource "aws_rds_cluster_parameter_group" "custom_aurora_postgresql" {
  # パラメータグループ名
  name = "${var.project_name}-custom-aurora-${var.aurora_engine}"
  # クラスターパラメータグループの適用先ファミリー
  family = var.aurora_cluster_parameter_group_family
  # 出力対象のSQL操作
  # none: 何も出力しない
  # ddl: DDL操作（CREATE,ALTER,DROPなど）だけ出力する
  # mod: DDL + DML（INSERT,UPDATE,DELETE）だけ出力する
  # all: すべてのSQL分（SELECTを含む）を出力する（CloudWatch Logsに大量にログが流れてコスト増大の原因になる為、指定注意）
  parameter {
    name  = "log_statement"
    value = "mod"
  }
  # 実行時間が指定ミリ秒以上のログだけを出力する
  # （0を指定すると、すべてのSQL文がCloudWatch Logsに流れてコスト増大の原因になる為、指定注意）
  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }
  # クライアントがDBに接続した時にログを出力するか（1:出力する）
  # 接続元IPやユーザーを確認することができる為、セキュリティや運用監視に有用。
  parameter {
    name  = "log_connections"
    value = "1"
  }
  # クライアントがDBから切断した時にログを出力するか（1:出力する）
  # クライアントのセッション時間や切断理由の把握に有用。
  parameter {
    name  = "log_disconnections"
    value = "1"
  }
  # 説明
  description = "${var.project_name} Custom parameter group for Aurora ${var.aurora_engine} ${var.aurora_engine_version}"
  # タグ
  tags = {
    Name              = "${var.project_name}-aurora-postgresql"
    ProjectName       = var.project_name
    ResourceCreatedBy = "terraform"
  }
}

# DBサブネットグループ（Auroraクラスターが利用するサブネットの集合）の作成
resource "aws_db_subnet_group" "aurora" {
  # サブネットグループ名
  name = "${var.project_name}-aurora-subnet-group"
  # グループの対象とするプライベートサブネットのID群
  subnet_ids = [for value in aws_subnet.private : value.id]
  # サブネットグループの説明
  description = "${var.project_name} Aurora Subnet Group for ${var.aurora_engine}"
  # タグ
  tags = {
    Name              = "${var.project_name}-aurora-postgresql-sg"
    ProjectName       = var.project_name
    ResourceCreatedBy = "terraform"
  }
}



#============================================================
# Security Group
#============================================================

# Aurora用のセキュリティグループ
resource "aws_security_group" "aurora" {
  # セキュリティグループ名
  name = "${var.project_name}-${var.aurora_engine}-sg"
  # 適用先のVPC
  vpc_id = aws_vpc.main.id
  # インバウントルールの設定（外部からこのセキュリティグループに所属するリソースへのアクセス許可設定）
  ingress {
    # 許可する開始ポート番号
    from_port = var.aurora_port
    # 許可する終了ポート番号
    to_port = var.aurora_port
    # 使用するプロトコル（tcpはPostgreSQLの通信プロトコル）
    protocol = "tcp"
    # アクセスを許可する送信元IPアドレスの範囲
    # このVPC内のすべてのIPアドレスを指定することで、このVPC内のLambdaなどのすべてのリソースからアクセスを許可する。
    cidr_blocks = [var.vpc_cidr]
    # 説明
    description = "Allow tcp to port ${var.aurora_port} from VPC"
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
    # 説明
    description = "Allow all outbound"
  }
  # セキュリティグループの説明
  description = "${var.project_name} Aurora Security Group for ${var.aurora_engine}"
  # タグ
  tags = {
    Name              = "${var.project_name}-aurora-postgresql-sg"
    ProjectName       = var.project_name
    ResourceCreatedBy = "terraform"
  }
}
