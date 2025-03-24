#============================================================
# AWS Backup
#============================================================

# AWS Backup Vault（バックアップデータを保存する場所）の作成
resource "aws_backup_vault" "backup_vault" {
  # Vault名
  name = "${var.project_name}-backup-${local.project_stage}"
  # Vaultの中にバックアップデータが入っていてもTerraformに削除を許可するかどうか(true:許可)
  force_destroy = var.backup_force_destroy
  # タグ
  tags = {
    ProjectName        = var.project_name
    ProjectStage       = local.project_stage
    ProjectDescription = var.project_description_tag
    ResourceCreatedBy  = "terraform"
  }
}

# AWS Backup Plan（バックアップのスケジュールとルール）の作成
resource "aws_backup_plan" "backup_plan" {
  # Plan名
  name = "${var.project_name}-backup-${local.project_stage}"
  # ルールの定義
  rule {
    # ルール名
    rule_name = "${var.project_name}-cognito-backup-${local.project_stage}"
    # ターゲットのVault名
    target_vault_name = aws_backup_vault.backup_vault.name
    # バックアップスケジュール(CRON形式で記述)
    schedule = "cron(0 16 * * ? *)" # 毎日深夜1時に実行(Cognitoユーザー情報一覧を毎日深夜0時にS3バケットに取得する為)
  }
  # タグ
  tags = {
    ProjectName        = var.project_name
    ProjectStage       = local.project_stage
    ProjectDescription = var.project_description_tag
    ResourceCreatedBy  = "terraform"
  }
}

# AWS Backup Selection（バックアップ対象リソースの設定）の作成
resource "aws_backup_selection" "backup_selection" {
  # Selection名
  name = "${var.project_name}-backup-${local.project_stage}"
  # PlanのID
  plan_id = aws_backup_plan.backup_plan.id
  # AWS Backup用IAMロールのARN
  iam_role_arn = aws_iam_role.backup_role.arn
  # バックアップ対象のリソースのARN
  resources = [
    # Cognitoのユーザー情報をバックアップしたS3バケットのARN
    aws_s3_bucket.bucket_cognito_backup.arn
  ]
}
