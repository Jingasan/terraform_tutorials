#============================================================
# 環境変数の定義（terraform.tfvarsの変数値を受け取る）
#============================================================
# プロジェクト名
variable "project_name" {}
#============================================================
# Resource Group
#============================================================
# ロケーション
variable "location" {}
#============================================================
# Azure Database for PostgreSQL
#============================================================
# PostgreSQLのバージョン
variable "db_postgres_version" {}
# コンピューティングサイズ（価格プラン）
variable "db_sku_name" {}
# ストレージサイズ (MB) (32GB - 32TB)
variable "db_storage_mb" {}
# バックアップ保存期間 (日) (7-35日)
variable "db_backup_retention_days" {}
# 管理者ユーザー名
variable "db_administrator_login" {}
# パスワード
variable "db_administrator_password" {}
# PostgreSQLサーバーへの接続を許可するIPのリスト
variable "db_firewall_allow_ip_list" {}
