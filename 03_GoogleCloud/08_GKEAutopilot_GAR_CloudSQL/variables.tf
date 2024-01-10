#============================================================
# 環境変数の定義（terraform.tfvarsの変数値を受け取る）
#============================================================
# プロジェクトID
variable "project_id" {}
# リージョン
variable "region" {}
#============================================================
# Artifact Registry
#============================================================
variable "gar_image_name" {}
#============================================================
# Cloud SQL
#============================================================
# データベースバージョン
variable "sql_database_version" {}
# ルートパスワード
variable "sql_root_password" {}
# Cloud SQL Edition
variable "sql_edition" {}
# ゾーンの可用性(ZONAL:シングルゾーン/REGIONAL:複数のゾーン)
variable "sql_availability_type" {}
# プライマリゾーン
variable "sql_zone" {}
# マシンの構成
variable "sql_tier" {}
# ストレージの種類(PD_SSD(default)(推奨)/PD_HDD)
variable "sql_disk_type" {}
# ストレージ容量(GB)
variable "sql_disk_size" {}
# ストレージの自動増量の有効化(true:有効)
variable "sql_disk_autoresize" {}
# 自動増量の最大サイズ(GB)
variable "sql_disk_autoresize_limit" {}
# バックアップ数
variable "sql_retained_backups" {}
# バックアップの開始時間(バックアップは開始時間から最大4時間)
variable "sql_backup_start_time" {}
# ログの日数(日)
variable "sql_transaction_log_retention_days" {}
# メンテナンス日(1:月,2:火,3:水,4:木,5:金,6:土,7:日)
variable "sql_maintenance_day" {}
# メンテナンス開始時間(0-23時)
variable "sql_maintenance_start_hour" {}
# SQLインスタンスのユーザー名
variable "sql_username" {}
# SQLインスタンスのユーザーパスワード
variable "sql_userpassword" {}
# SQLインスタンス起動時に作成するデータベース名
variable "sql_databasename" {}
