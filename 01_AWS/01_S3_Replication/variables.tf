#============================================================
# 環境変数の定義（terraform.tfvarsの変数値を受け取る）
#============================================================
# プロジェクト名（リソースの名前、タグ、説明文などに利用される）
# プロジェクト毎に他のプロジェクトと被らないユニークな名前を指定すること（小文字英数字かハイフンのみ有効）
variable "project_name" {
  type        = string
  description = "プロジェクト名（リソースの名前、タグ、説明文などに利用される）"
  default     = "terraform-tutorials"
}
#============================================================
# AWS Account
#============================================================
# メインリージョン
variable "aws_region" {
  type        = string
  description = "メインリージョン"
  default     = "ap-northeast-1"
}
# AWSアクセスキーのプロファイル
variable "aws_profile" {
  type        = string
  description = "AWSアクセスキーのプロファイル"
  default     = "default"
}
#============================================================
# S3
#============================================================
# バックアップ複製先リージョン
variable "s3_replication_region" {
  type        = string
  description = "バックアップ複製先リージョン"
  default     = "ap-northeast-3"
}
# 非最新バージョンの保持日数（日）：1以上の値を指定。指定日数が経過したら非最新バージョンを削除される。
variable "s3_lifecycle_noncurrent_version_expiration_days" {
  type        = number
  description = "非最新バージョンの保持日数（日）：1以上の値を指定。指定日数が経過したら非最新バージョンを削除される。"
  default     = 1
}
# 保持するバージョン数（個）：1~100
variable "s3_lifecycle_newer_noncurrent_versions" {
  type        = number
  description = "保持するバージョン数（個）：1~100"
  default     = 1
}
