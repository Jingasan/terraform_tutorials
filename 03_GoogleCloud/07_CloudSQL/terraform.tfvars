#============================================================
# 環境変数の定義
#============================================================
# リージョン
region = "asia-northeast1"
#============================================================
# Cloud SQL
#============================================================
# データベースバージョン
sql_database_version = "POSTGRES_15"
# ルートパスワード
sql_root_password = "Password_1234"
# Cloud SQL Edition
sql_edition = "ENTERPRISE"
# ゾーンの可用性(ZONAL:シングルゾーン/REGIONAL:複数のゾーン)
sql_availability_type = "ZONAL"
# プライマリゾーン
sql_zone = "asia-northeast1-b"
# マシンの構成
sql_tier = "db-custom-1-3840"
# ストレージの種類(PD_SSD(default)(推奨)/PD_HDD)
sql_disk_type = "PD_SSD"
# ストレージ容量(GB)
sql_disk_size = 10
# ストレージの自動増量の有効化(true:有効)
sql_disk_autoresize = true
# 自動増量の最大サイズ(GB)
sql_disk_autoresize_limit = 10
# バックアップ数
sql_retained_backups = 7
# バックアップの開始時間(バックアップは開始時間から最大4時間)
sql_backup_start_time = "12:00"
# ログの日数(日)
sql_transaction_log_retention_days = 7
# メンテナンス日(1:月,2:火,3:水,4:木,5:金,6:土,7:日)
sql_maintenance_day = 1
# メンテナンス開始時間(0-23時)
sql_maintenance_start_hour = 0
