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