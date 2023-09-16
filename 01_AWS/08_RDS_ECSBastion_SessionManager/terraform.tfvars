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
# ECS
#============================================================
# ECSで起動するコンテナ名
ecs_container_name = "BastionContainer"
# ECSで起動するイメージ名
ecs_container_image = "ubuntu:22.04"
# ECSで起動するコンテナのvCPU数
ecs_container_vcpu = "256" # 0.25vCPU
# ECSで起動するコンテナのメモリサイズ
ecs_container_memory = "512" # 0.5GB