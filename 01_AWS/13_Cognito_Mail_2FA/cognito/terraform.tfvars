#============================================================
# 環境変数値
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
# Secrets Manager
#============================================================
# 削除後のシークレット保存期間（日）
secret_manager_recovery_window_in_days = 0 # 保存しない
#============================================================
# Cognito
#============================================================
# ユーザープールの削除保護(INACTIVE(default):ユーザープールの削除を許可/ACTIVE:ユーザープールの削除を拒否)
cognito_deletion_protection = "INACTIVE"
# IDトークンの有効期限(秒)(5分-1日の範囲で指定)
cognito_id_token_validity = 3600
# アクセストークンの有効期限(秒)(5分-1日の範囲で指定)
cognito_access_token_validity = 3600
# リフレッシュトークンの有効期限(秒)
# 60分-10年の範囲で指定, IDトークン/アクセストークンよりも長い時間を指定すること
cognito_refresh_token_validity = 2592000
# 認証フローセッションの持続期間(分)(3-15分の範囲で指定)
cognito_auth_session_validity = 3
# メールの送信元アドレス(SESで事前に確認済みのメールアドレス)
cognito_from_email_address = "user@domain"
# パスワードの最低文字数
cognito_password_minimum_length = 8
# パスワードに大文字を必須とするか
cognito_password_require_uppercase = false
# パスワードに小文字を必須とするか
cognito_password_require_lowercase = false
# パスワードに数字を必須とするか
cognito_password_require_numbers = false
# パスワードに記号を必須とするか
cognito_password_require_symbols = false
# 仮パスワードの有効期間(日)
cognito_temporary_password_validity_days = 90
# 以前のパスワードの再利用防止(指定回数まで)
cognito_password_history_size = 2
# パスワード有効期間(日)
cognito_password_expiration_days = 90
#============================================================
# Lambda
#============================================================
# 実行ランタイム（ex: nodejs, python, go, etc.）
lambda_runtime = "nodejs22.x"
# Lambda関数のタイムアウト時間
lambda_timeout = 900
# CloudWatchにログを残す期間（日）
lambda_cloudwatch_log_retention_in_days = 90
#============================================================
# AWS Backup
#============================================================
# Vaultの中にバックアップデータが入っていてもTerraformに削除を許可するかどうか(true:許可)
backup_force_destroy = true
#============================================================
# S3
#============================================================
# 非最新バージョンの保持日数(日)：指定日数が経過したら非最新バージョンを削除する
s3_bucket_lifecycle_noncurrent_version_expiration_days = 90
# 保持するバージョン数(個)：1~100
s3_bucket_lifecycle_newer_noncurrent_versions = 10