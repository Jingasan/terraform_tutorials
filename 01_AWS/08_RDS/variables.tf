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
