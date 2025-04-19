#============================================================
# SNS
#============================================================

# SNSトピックの作成（メインのAWS Backup Vaultでのバックアップ失敗通知用）
resource "aws_sns_topic" "main_backup_failure_topic" {
  # SNSトピック名
  name = "${var.project_name}-main-backup-failure-${local.project_stage}"
  # タグ
  tags = {
    ProjectName        = var.project_name
    ProjectStage       = local.project_stage
    ProjectDescription = var.project_description_tag
    ResourceCreatedBy  = "terraform"
  }
}

# SNSトピックの作成（複製先のAWS Backup Vaultでのバックアップ失敗通知用）
resource "aws_sns_topic" "clone_backup_failure_topic" {
  # バックアップの複製先リージョン（複製元のVaultとは別リージョンを指定）
  provider = aws.backup_clone_region
  # SNSトピック名
  name = "${var.project_name}-clone-backup-failure-${local.project_stage}"
  # タグ
  tags = {
    ProjectName        = var.project_name
    ProjectStage       = local.project_stage
    ProjectDescription = var.project_description_tag
    ResourceCreatedBy  = "terraform"
  }
}

# メール通知のサブスクリプション（メインのAWS Backup Vaultでのバックアップ失敗通知用）
resource "aws_sns_topic_subscription" "main_backup_email_subscription" {
  # SNSトピックのARN
  topic_arn = aws_sns_topic.main_backup_failure_topic.arn
  # SNSの通知プロトコル(application/email/email-json/firehose/http/https/lambda/sms/sqs)
  protocol = "email"
  # SNS通知先のメールアドレス
  endpoint = var.sns_to_email_address
}

# メール通知のサブスクリプション（複製先のAWS Backup Vaultでのバックアップ失敗通知用）
resource "aws_sns_topic_subscription" "clone_backup_email_subscription" {
  # バックアップの複製先リージョン（複製元のVaultとは別リージョンを指定）
  provider = aws.backup_clone_region
  # SNSトピックのARN
  topic_arn = aws_sns_topic.clone_backup_failure_topic.arn
  # SNSの通知プロトコル(application/email/email-json/firehose/http/https/lambda/sms/sqs)
  protocol = "email"
  # SNS通知先のメールアドレス
  endpoint = var.sns_to_email_address
}

# EventBridgeルールを作成（メインのAWS Backup Vaultでのバックアップ失敗イベントをキャッチ）
resource "aws_cloudwatch_event_rule" "main_backup_failure" {
  # イベントルール名
  name = "${var.project_name}-main-backup-failure-${local.project_stage}"
  # イベント発火条件：AWS Backupの特定のVaultでバックアップジョブが失敗した場合
  event_pattern = jsonencode({
    source        = ["aws.backup"],
    "detail-type" = ["Backup Job State Change"],
    detail = {
      state           = ["FAILED", "EXPIRED", "ABORTED", "PARTIAL"],
      backupVaultName = ["${aws_backup_vault.main.name}"]
    }
  })
  # 説明
  description = "${var.project_name} Trigger on AWS Backup Failure"
  # タグ
  tags = {
    ProjectName        = var.project_name
    ProjectStage       = local.project_stage
    ProjectDescription = var.project_description_tag
    ResourceCreatedBy  = "terraform"
  }
}

# EventBridgeルールを作成（複製先のAWS Backup Vaultでのバックアップ失敗イベントをキャッチ）
resource "aws_cloudwatch_event_rule" "clone_backup_failure" {
  # バックアップの複製先リージョン（複製元のVaultとは別リージョンを指定）
  provider = aws.backup_clone_region
  # イベントルール名
  name = "${var.project_name}-clone-backup-failure-${local.project_stage}"
  # イベント発火条件：AWS Backupの特定のVaultでバックアップジョブが失敗した場合
  event_pattern = jsonencode({
    source        = ["aws.backup"],
    "detail-type" = ["Backup Job State Change"],
    detail = {
      state           = ["FAILED", "EXPIRED", "ABORTED", "PARTIAL"],
      backupVaultName = ["${aws_backup_vault.clone.name}"]
    }
  })
  # 説明
  description = "${var.project_name} Trigger on AWS Backup Failure"
  # タグ
  tags = {
    ProjectName        = var.project_name
    ProjectStage       = local.project_stage
    ProjectDescription = var.project_description_tag
    ResourceCreatedBy  = "terraform"
  }
}

# CloudWatchイベントターゲットの設定（メインのAWS Backup Vaultでのバックアップ失敗通知用）
resource "aws_cloudwatch_event_target" "main_backup_failure_target" {
  # ターゲットID
  target_id = "${var.project_name}-main-backup-failure-${local.project_stage}"
  # イベントルール
  rule = aws_cloudwatch_event_rule.main_backup_failure.name
  # ターゲットとなるSNSトピックのARN
  arn = aws_sns_topic.main_backup_failure_topic.arn
}

# CloudWatchイベントターゲットの設定（複製先のAWS Backup Vaultでのバックアップ失敗通知用）
resource "aws_cloudwatch_event_target" "clone_backup_failure_target" {
  # バックアップの複製先リージョン（複製元のVaultとは別リージョンを指定）
  provider = aws.backup_clone_region
  # ターゲットID
  target_id = "${var.project_name}-clone-backup-failure-${local.project_stage}"
  # イベントルール
  rule = aws_cloudwatch_event_rule.clone_backup_failure.name
  # ターゲットとなるSNSトピックのARN
  arn = aws_sns_topic.clone_backup_failure_topic.arn
}

# SNSトピックにEventBridgeからの実行権限を付与（メインのAWS Backup Vaultでのバックアップ失敗通知用）
resource "aws_sns_topic_policy" "main_backup_failure_policy" {
  # SNSトピックのARN
  arn = aws_sns_topic.main_backup_failure_topic.arn
  # ポリシー
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "events.amazonaws.com"
        },
        Action   = "sns:Publish",
        Resource = "${aws_sns_topic.main_backup_failure_topic.arn}"
      }
    ]
  })
}

# SNSトピックにEventBridgeからの実行権限を付与（複製先のAWS Backup Vaultでのバックアップ失敗通知用）
resource "aws_sns_topic_policy" "clone_backup_failure_policy" {
  # バックアップの複製先リージョン（複製元のVaultとは別リージョンを指定）
  provider = aws.backup_clone_region
  # SNSトピックのARN
  arn = aws_sns_topic.clone_backup_failure_topic.arn
  # ポリシー
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "events.amazonaws.com"
        },
        Action   = "sns:Publish",
        Resource = "${aws_sns_topic.clone_backup_failure_topic.arn}"
      }
    ]
  })
}
