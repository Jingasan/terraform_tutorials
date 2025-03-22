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
# AWS Backup
#============================================================
# Vaultの中にバックアップデータが入っていてもTerraformに削除を許可するかどうか(true:許可)
backup_force_destroy = true
# バックアップスケジュール(CRON形式で記述)
backup_schedule = "cron(0 16 * * ? *)" # 毎日深夜1時に実行
# 何日後にバックアップデータを削除するか(日)
backup_delete_after = 365
# コールドストレージ保存（低コストの長期保存）（DynamoDB/EBS/FSx/RDS対象）の有効化（true:有効）
# コールドストレージに保存するリソースは最低でも月単位以上の低頻度でのバックアップでなければならない
backup_opt_in_to_archive_for_supported_resources = false
# 何日後に安価で低速なコールドストレージに移行するか（DynamoDB/EBS/FSx/RDS対象）
# opt_in_to_archive_for_supported_resourcesがtrue、かつdelete_afterよりも90日以上小さい値である必要がある
backup_cold_storage_after = 1
#============================================================
# S3
#============================================================
# 非最新バージョンの保持日数(日)：指定日数が経過したら非最新バージョンを削除する
s3_bucket_lifecycle_noncurrent_version_expiration_days = 90
# 保持するバージョン数(個)：1~100
s3_bucket_lifecycle_newer_noncurrent_versions = 10
