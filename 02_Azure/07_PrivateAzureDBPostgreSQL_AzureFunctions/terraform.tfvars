#============================================================
# 環境変数の定義
#============================================================
# プロジェクト名
project_name = "terraformtutorial"
#============================================================
# Resource Group
#============================================================
# ロケーション
location = "japaneast"
#============================================================
# Azure Database for PostgreSQL
#============================================================
# PostgreSQLのバージョン
db_postgres_version = "15"
# コンピューティングサイズ（価格プラン）
db_sku_name = "B_Standard_B1ms"
# ストレージサイズ (MB) (32GB - 32TB)
db_storage_mb = 32768
# バックアップ保存期間 (日) (7-35日)
db_backup_retention_days = 7
# 管理者ユーザー名
db_administrator_login = "postgres"
# パスワード
db_administrator_password = "P0stgres"
#============================================================
# Azure Functions
#============================================================
# App Serviceの価格プラン (Y1/EP1/EP2/EP3/B1/B2/B3/S1/S2/S3/P1v2/P2v2/P3v2)
# https://azure.microsoft.com/ja-jp/pricing/details/app-service/linux/
functions_sku_name = "B1"
# Azure FunctionsのNodeランタイムのバージョン
functions_node_version = "18"
#============================================================
# Blob Storage (Azure Functions用)
#============================================================
# 価格プラン (Standard/Premium)
storage_account_tier = "Standard"
# 冗長性 (LRS/GRS/RAGRS/ZRS/GZRS/RAGZRS)
storage_account_replication_type = "LRS"