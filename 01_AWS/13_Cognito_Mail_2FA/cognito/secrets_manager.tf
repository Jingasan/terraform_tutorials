#============================================================
# Secrets Manager
#============================================================

# RDS用のSecretの作成
resource "aws_secretsmanager_secret" "secretsmanager" {
  # Secret名
  name = "${var.project_name}-${local.project_stage}"
  # 削除後のシークレット保存期間（日）
  recovery_window_in_days = var.secret_manager_recovery_window_in_days
  # 説明
  description = var.project_name
  # タグ
  tags = {
    ProjectName        = var.project_name
    ProjectStage       = local.project_stage
    ProjectDescription = var.project_description_tag
    ResourceCreatedBy  = "terraform"
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
    # Cognitoのユーザー情報をバックアップするバケット名
    cognitoBackupBucketName = "${aws_s3_bucket.bucket_cognito_backup.bucket}"
    # Vault名の一覧
    vaultNames = ["${aws_backup_vault.main.name}"]
    # 保持する世代数:1~100（指定した世代よりも古い世代のバックアップはすべて削除する）
    keepGenerations = "${var.backup_keep_generations}"
  })
}
