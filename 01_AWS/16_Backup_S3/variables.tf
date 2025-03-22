#============================================================
# 環境変数の定義（terraform.tfvarsの変数値を受け取る）
#============================================================
# プロジェクト名
variable "project_name" {
  type        = string
  description = "プロジェクト名（リソースの名前、タグ、説明文に利用される）"
  default     = "terraform-tutorials"
}
#============================================================
# AWS Account
#============================================================
# AWSのリージョン
variable "region" {
  type        = string
  description = "AWSのリージョン"
  default     = "ap-northeast-1"
}
# AWSアクセスキーのプロファイル
variable "profile" {
  type        = string
  description = "AWSアクセスキーのプロファイル"
  default     = "default"
}
#============================================================
# AWS Backup
#============================================================
# Vaultの中にバックアップデータが入っていてもTerraformに削除を許可するかどうか(true:許可)
variable "backup_force_destroy" {
  type        = bool
  description = "Vaultの中にバックアップデータが入っていてもTerraformに削除を許可するかどうか(true:許可)"
  default     = false
}
# バックアップスケジュール(CRON形式で記述)
variable "backup_schedule" {
  type        = string
  description = "バックアップスケジュール(CRON形式で記述)"
  default     = "cron(0 16 * * ? *)" # 毎日深夜1時に実行
}
# 何日後にバックアップデータを削除するか(日)（90日以上である必要がある）
variable "backup_delete_after" {
  type        = number
  description = "何日後にバックアップデータを削除するか（90日以上である必要がある）"
  default     = 365
}
# コールドストレージ保存（低コストの長期保存）（DynamoDB/EBS/FSx/RDS対象）の有効化（true:有効）
# コールドストレージに保存するリソースは最低でも月単位以上の低頻度でのバックアップでなければならない
variable "backup_opt_in_to_archive_for_supported_resources" {
  type        = bool
  description = "コールドストレージ（低コストの長期保存）の有効化（true:有効）"
  default     = false
}
# 何日後に安価で低速なコールドストレージに移行するか（DynamoDB/EBS/FSx/RDS対象）
# opt_in_to_archive_for_supported_resourcesがtrue、かつdelete_afterよりも90日以上小さい値である必要がある
variable "backup_cold_storage_after" {
  type        = number
  description = "何日後に安価で低速なコールドストレージ（S3 Glacier）に移行するか"
  default     = null
}
#============================================================
# S3
#============================================================
# 非最新バージョンの保持日数(日)：指定日数が経過したら非最新バージョンを削除する
variable "s3_bucket_lifecycle_noncurrent_version_expiration_days" {
  type        = number
  description = "非最新バージョンの保持日数(日)：指定日数が経過したら非最新バージョンを削除する"
  default     = 90
}

# 保持するバージョン数(個)：1~100
variable "s3_bucket_lifecycle_newer_noncurrent_versions" {
  type        = number
  description = "保持するバージョン数(個)：1~100"
  default     = 10
}
