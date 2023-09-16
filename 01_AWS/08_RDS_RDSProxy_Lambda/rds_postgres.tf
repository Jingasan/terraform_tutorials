#============================================================
# RDS PostgreSQL
#============================================================

# RDSインスタンスの構築
resource "aws_db_instance" "rds" {
  # DBエンジン（postgres/mysql）
  engine = var.rds_engine
  # DBバージョン
  engine_version = var.rds_engine_version
  # マルチAZに複数DBインスタンスを作成するか
  multi_az = false
  # DBインスタンス識別子
  identifier = "${var.project_name}-${var.rds_engine}"
  # 初期DB名
  db_name = var.rds_dbname
  # DBポート番号
  port = var.rds_port
  # DBマスターユーザー名
  username = var.rds_username
  # DBマスターパスワード
  password = var.rds_password
  # インスタンス
  instance_class = var.rds_instance_class
  # ストレージタイプ
  storage_type = var.rds_storage_type
  # ストレージの割り当て量（GB）
  allocated_storage = var.rds_allocated_storage
  # ストレージの自動スケーリングの有効化とスケーリング時の最大ストレージ量（GB）
  max_allocated_storage = var.rds_max_allocated_storage
  # DBサブネットグループ
  db_subnet_group_name = aws_db_subnet_group.rds.name
  # パブリックアクセスの有効化
  publicly_accessible = false
  # VPCセキュリティグループ
  vpc_security_group_ids = [aws_security_group.rds.id]
  # 認証機関（CA）の設定
  ca_cert_identifier = "rds-ca-rsa4096-g1"
  # IAMデータベース認証の有効化
  iam_database_authentication_enabled = true
  # Performance Insightsの有効化
  performance_insights_enabled = true
  # Performance Insightsの保持期間
  performance_insights_retention_period = 7
  # DBインスタンス削除時のスナップショット保存をスキップするか
  skip_final_snapshot = true
  # DBバックアップの保持期間（日）
  backup_retention_period = var.rds_backup_retention_period
  # スナップショットにタグをコピーするか
  copy_tags_to_snapshot = true
  # ストレージを暗号化するか
  storage_encrypted = true
  # DBのマイナーバージョンアップの有効化
  auto_minor_version_upgrade = true
  # terraform apply実行時に変更をすぐに反映するか（false：次回の定期メンテナンス期間中に適用される）
  apply_immediately = true
  # 誤りによるDB削除を防ぐ削除保護機能の有効化（true：DBの削除を禁止する）
  deletion_protection = false
  # タグ
  tags = {
    Name = "${var.project_name}-${var.rds_engine}"
  }
}



#============================================================
# Subnet Group
#============================================================

# サブネットグループの作成
locals {
  public_subnet_ids  = [for value in aws_subnet.public : value.id]
  private_subnet_ids = [for value in aws_subnet.private : value.id]
}
resource "aws_db_subnet_group" "rds" {
  # サブネットグループ名
  name = "${var.project_name}-${var.rds_engine}"
  # サブネットグループの説明
  description = "RDS Subnet Group for ${var.rds_engine}"
  # サブネットID
  subnet_ids = concat(
    local.public_subnet_ids,
    local.private_subnet_ids
  )
  # タグ
  tags = {
    Name = "${var.project_name}-${var.rds_engine}"
  }
}



#============================================================
# Security Group
#============================================================

# RDS用のセキュリティグループ
resource "aws_security_group" "rds" {
  # セキュリティグループ名
  name = "${var.project_name}-${var.rds_engine}-sg"
  # セキュリティグループの説明
  description = "RDS Security Group for ${var.rds_engine}"
  # 適用先のVPC
  vpc_id = aws_vpc.default.id
  # タグ
  tags = {
    Name = "${var.project_name}-${var.rds_engine}"
  }
}
# LambdaなどのRDS（RDS Proxy）に接続するアプリ用のセキュリティグループ
resource "aws_security_group" "rds_app" {
  # セキュリティグループ名
  name = "${var.project_name}-${var.rds_engine}-app-sg"
  # セキュリティグループの説明
  description = "RDS Security Group for app"
  # 適用先のVPC
  vpc_id = aws_vpc.default.id
  # タグ
  tags = {
    Name = "${var.project_name}-${var.rds_engine}"
  }
}

# RDSのセキュリティグループに割り当てるRDS Proxy用のインバウンドルール
resource "aws_security_group_rule" "rds_ingress_rdsproxy" {
  # 割り当て先のセキュリティグループID
  security_group_id = aws_security_group.rds.id
  # typeをingressにすることでインバウンドルールになる
  type = "ingress"
  # 通信を許可するプロトコル/ポート番号/セキュリティグループ
  protocol                 = "tcp"
  from_port                = var.rds_port
  to_port                  = var.rds_port
  source_security_group_id = aws_security_group.rds.id
  # 説明
  description = "${var.project_name} ${var.rds_engine} sgr for RDS Proxy"
}
# RDSのセキュリティグループに割り当てるLambdaなどのアプリ用のインバウンドルール
resource "aws_security_group_rule" "rds_ingress_app" {
  # 割り当て先のセキュリティグループID
  security_group_id = aws_security_group.rds.id
  # typeをingressにすることでインバウンドルールになる
  type = "ingress"
  # 通信を許可するプロトコル/ポート番号/セキュリティグループ
  protocol                 = "tcp"
  from_port                = var.rds_port
  to_port                  = var.rds_port
  source_security_group_id = aws_security_group.rds_app.id
  # 説明
  description = "${var.project_name} ${var.rds_engine} sgr for App"
}
# RDSのセキュリティグループに割り当てるアウトバウンドルール
resource "aws_security_group_rule" "rds_egress_all" {
  # 割り当て先のセキュリティグループID
  security_group_id = aws_security_group.rds.id
  # typeをegressにすることでアウトバウンドルールになる
  type = "egress"
  # すべての通信を許可
  from_port   = 0
  to_port     = 0
  protocol    = "all"
  cidr_blocks = ["0.0.0.0/0"]
  # 説明
  description = "${var.project_name} ${var.rds_engine} sgr"
}
