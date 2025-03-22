#============================================================
# AWS Backup
#============================================================

# AWS Backup Vault（バックアップデータを保存する場所）の作成
resource "aws_backup_vault" "backup_vault" {
  # Vault名
  name = "${var.project_name}-backup-${local.lower_random_hex}"
  # Vaultの中にバックアップデータが入っていてもTerraformに削除を許可するかどうか(true:許可)
  force_destroy = var.backup_force_destroy
  # タグ
  tags = {
    "Name" = var.project_name
  }
}

# AWS Backup Plan（バックアップのスケジュールとルール）の作成
resource "aws_backup_plan" "backup_plan" {
  # Plan名
  name = "${var.project_name}-backup-${local.lower_random_hex}"
  # ルールの定義
  rule {
    # ルール名
    rule_name = "${var.project_name}-cognito-backup-${local.lower_random_hex}"
    # ターゲットのVault名
    target_vault_name = aws_backup_vault.backup_vault.name
    # バックアップスケジュール
    schedule = "cron(0 16 * * ? *)" # 毎日深夜1時に実行
    # バックアップデータのライフサイクル
    lifecycle {
      # 何日後にバックアップデータを削除するか(日)
      delete_after = var.backup_delete_after
      # コールドストレージ保存（低コストの長期保存）の有効化（true:有効）
      opt_in_to_archive_for_supported_resources = true
      # 何日後に安価で低速なコールドストレージ（S3 Glacier）に移行するか
      # opt_in_to_archive_for_supported_resourcesがtrue、かつdelete_afterよりも小さい値である必要がある
      cold_storage_after = 0
    }
    # バックアップを別リージョンに複製する場合
    # copy_action {
    #   # 複製先のVaultのARN
    #   destination_vault_arn = "arn:aws:backup::アカウントID:backup-vault:大阪リージョンに作成したボールト名"
    #   # バックアップデータのライフサイクル
    #   lifecycle {
    #     # 何日後にバックアップデータを削除するか(日)
    #     delete_after = var.backup_delete_after
    #     # 何日後に安価で低速なコールドストレージ（S3 Glacier）に移行するか
    #     cold_storage_after = 0
    #     # アーカイブ（低コストの長期保存）の有効化（true:有効化）
    #     opt_in_to_archive_for_supported_resources = true
    #   }
    # }
  }
  # タグ
  tags = {
    "Name" = var.project_name
  }
}

# AWS Backup Selection（バックアップ対象リソースの設定）の作成
resource "aws_backup_selection" "backup_selection" {
  # Selection名
  name = "${var.project_name}-backup-${local.lower_random_hex}"
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
