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
    # バックアップスケジュール(CRON形式で記述)
    schedule = var.backup_schedule # 毎日深夜1時に実行
    # バックアップデータのライフサイクル
    lifecycle {
      # 何日後にバックアップデータを削除するか(日)
      delete_after = var.backup_delete_after
      # コールドストレージ保存（低コストの長期保存）の有効化（true:有効）
      # コールドストレージに保存するリソースは最低でも月単位以上の低頻度でのバックアップでなければならない
      opt_in_to_archive_for_supported_resources = var.backup_opt_in_to_archive_for_supported_resources
      # 何日後に安価で低速なコールドストレージ（S3 Glacier）に移行するか
      # opt_in_to_archive_for_supported_resourcesがtrue、かつdelete_afterよりも小さい値である必要がある
      cold_storage_after = var.backup_cold_storage_after
    }
    # バックアップを別リージョンに複製する場合
    # copy_action {
    #   # 複製先のVaultのARN
    #   destination_vault_arn = "arn:aws:backup::アカウントID:backup-vault:大阪リージョンに作成したボールト名"
    #   # バックアップデータのライフサイクル
    #   lifecycle {
    #     # 何日後にバックアップデータを削除するか(日)
    #     delete_after = var.backup_delete_after
    #     # コールドストレージ保存（低コストの長期保存）の有効化（true:有効）
    #     # コールドストレージに保存するリソースは最低でも月単位以上の低頻度でのバックアップでなければならない
    #     opt_in_to_archive_for_supported_resources = var.backup_opt_in_to_archive_for_supported_resources
    #     # 何日後に安価で低速なコールドストレージ（S3 Glacier）に移行するか
    #     # opt_in_to_archive_for_supported_resourcesがtrue、かつdelete_afterよりも小さい値である必要がある
    #     cold_storage_after = var.backup_cold_storage_after
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
    aws_s3_bucket.frontend.arn
  ]
}


#============================================================
# AWS Backup関連のIAMロール
#============================================================

# IAMロールの設定
resource "aws_iam_role" "backup_role" {
  # IAMロール名
  name = "${var.project_name}-backup-${local.lower_random_hex}"
  # AWS Backupに割り当てるIAMポリシー
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  # 説明
  description = var.project_name
  # タグ
  tags = {
    Name = var.project_name
  }
}

# IAMロールにAWSマネージドのDynamoDB/RDS/EC2などのバックアップポリシーを割り当て
resource "aws_iam_role_policy_attachment" "backup_policy_attachment" {
  # IAMロール
  role = aws_iam_role.backup_role.name
  # 割り当てるポリシーのARN
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# IAMロールにAWSマネージドのS3バックアップポリシーを割り当て
resource "aws_iam_role_policy_attachment" "backup_s3_policy_attachment" {
  # IAMロール
  role = aws_iam_role.backup_role.name
  # 割り当てるポリシーのARN
  policy_arn = "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Backup"
}

# IAMロールにAWSマネージドのDynamoDB/RDS/EC2などのリストアポリシーを割り当て
resource "aws_iam_role_policy_attachment" "restore_policy_attachment" {
  # IAMロール
  role = aws_iam_role.backup_role.name
  # 割り当てるポリシーのARN
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# IAMロールにAWSマネージドのS3リストアポリシーを割り当て
resource "aws_iam_role_policy_attachment" "restore_s3_policy_attachment" {
  # IAMロール
  role = aws_iam_role.backup_role.name
  # 割り当てるポリシーのARN
  policy_arn = "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Restore"
}
