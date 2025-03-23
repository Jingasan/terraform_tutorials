#============================================================
# 環境変数の定義
#============================================================
# プロジェクト名
variable "project_name" {
  type        = string
  description = "プロジェクト名（リソースの名前、タグ、説明文に利用される）"
  default     = "terraform-tutorials"
}
# プロジェクトのステージ名（例：dev/prod/test/個人名）
variable "project_stage" {
  type        = string
  description = "プロジェクトのステージ名（例：dev/prod/test/個人名）"
  default     = null
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
# Secrets Manager
#============================================================
# 削除後のシークレット保存期間（日）
variable "secret_manager_recovery_window_in_days" {
  type        = number
  description = "削除後のシークレット保存期間（日）"
  default     = 0
}
#============================================================
# Cognito
#============================================================
# ユーザープールの削除保護(INACTIVE(default):ユーザープールの削除を許可/ACTIVE:ユーザープールの削除を拒否)
variable "cognito_deletion_protection" {
  type        = string
  description = "ユーザープールの削除保護（INACTIVE(default):ユーザープールの削除を許可/ACTIVE:ユーザープールの削除を拒否）"
  default     = "ACTIVE"
}
# IDトークンの有効期限(秒)(5分-1日の範囲で指定)
variable "cognito_id_token_validity" {
  type        = number
  description = "IDトークンの有効期限(秒)(5分-1日の範囲で指定)"
  default     = 3600
}
# アクセストークンの有効期限(秒)(5分-1日の範囲で指定)
variable "cognito_access_token_validity" {
  type        = number
  description = "アクセストークンの有効期限(秒)(5分-1日の範囲で指定)"
  default     = 3600
}
# リフレッシュトークンの有効期限(秒)
# 60分-10年の範囲で指定, IDトークン/アクセストークンよりも長い時間を指定すること
variable "cognito_refresh_token_validity" {
  type        = number
  description = "リフレッシュトークンの有効期限(秒)"
  default     = 2592000
}
# 認証フローセッションの持続期間(分)(3-15分の範囲で指定)
variable "cognito_auth_session_validity" {
  type        = number
  description = "認証フローセッションの持続期間(分)(3-15分の範囲で指定)"
  default     = 3
}
# メールの送信元アドレス
variable "cognito_from_email_address" {
  type        = string
  description = "メールの送信元アドレス(SESで事前に確認済みのメールアドレス)"
  default     = "email@domain"
}
# パスワードの最低文字数
variable "cognito_password_minimum_length" {
  type        = number
  description = "パスワードの最低文字数"
  default     = 8
}
# パスワードに大文字を必須とするか
variable "cognito_password_require_uppercase" {
  type        = bool
  description = "パスワードに大文字を必須とするか"
  default     = false
}
# パスワードに小文字を必須とするか
variable "cognito_password_require_lowercase" {
  type        = bool
  description = "パスワードに小文字を必須とするか"
  default     = false
}
# パスワードに数字を必須とするか
variable "cognito_password_require_numbers" {
  type        = bool
  description = "パスワードに数字を必須とするか"
  default     = false
}
# パスワードに記号を必須とするか
variable "cognito_password_require_symbols" {
  type        = bool
  description = "パスワードに記号を必須とするか"
  default     = false
}
# 仮パスワードの有効期間(日)
variable "cognito_temporary_password_validity_days" {
  type        = number
  description = "仮パスワードの有効期間(日)"
  default     = 90
}
# 以前のパスワードの再利用防止(指定回数まで)
variable "cognito_password_history_size" {
  type        = number
  description = "以前のパスワードの再利用防止(指定回数まで)"
  default     = 2
}
# パスワード有効期間(日)
variable "cognito_password_expiration_days" {
  type        = number
  description = "パスワード有効期間(日)"
  default     = 90
}
#============================================================
# Lambda
#============================================================
# 実行ランタイム（ex: nodejs, python, go, etc.）
variable "lambda_runtime" {
  type        = string
  description = "実行ランタイム（ex: nodejs, python, go, etc.）"
  default     = "nodejs22.x"
}
# Lambda関数のタイムアウト時間
variable "lambda_timeout" {
  type        = number
  description = "Lambda関数のタイムアウト時間"
  default     = 900
}
# CloudWatchにログを残す期間（日）
variable "lambda_cloudwatch_log_retention_in_days" {
  type        = number
  description = "CloudWatchにログを残す期間（日）"
  default     = 90
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
