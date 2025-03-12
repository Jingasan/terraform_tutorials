#============================================================
# Secrets Manager
#============================================================

# RDS用のSecretの作成
resource "aws_secretsmanager_secret" "secretsmanager" {
  # Secret名
  name = var.project_name
  # 削除後のシークレット保存期間（日）
  recovery_window_in_days = var.secret_manager_recovery_window_in_days
  # 説明
  description = var.project_name
  # タグ
  tags = {
    Name = var.project_name
  }
}

# シークレット値の設定
resource "aws_secretsmanager_secret_version" "secretsmanager" {
  # 値の設定先となるシークレットID
  secret_id = aws_secretsmanager_secret.secretsmanager.id
  # シークレット値
  secret_string = jsonencode({
    # CognitoのユーザープールID
    cognitoUserPoolId = "${aws_cognito_user_pool.user_pool.id}"
    # CognitoのアプリクライアントID
    cognitoAppClientId = "${aws_cognito_user_pool_client.user_pool.id}"
    # パスワード有効期限日(日)
    passwordExpirationDays = "${var.cognito_password_expiration_days}"
    # パスワード有効期限日の何日前から通知を行うか(日)
    reminderDaysBeforePasswordExpiry = "${var.cognito_reminder_days_before_password_expiry}"
  })
}
