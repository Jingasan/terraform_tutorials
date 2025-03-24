#============================================================
# Lambda関連のIAMロール
#============================================================

# IAMロールの設定
resource "aws_iam_role" "lambda_role" {
  # IAMロール名
  name = "${var.project_name}-lambda-iam-role"
  # IAMロールの対象となるAWSサービスの指定
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
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

# IAMロールに紐付けるポリシーの設定
resource "aws_iam_policy" "lambda_policy" {
  # ポリシー名
  name = "${var.project_name}-lambda-iam-policy"
  # ポリシー(どのAWSリソースにどのような操作を許可するか)の定義
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        # 許可する操作の指定
        Action = [
          "logs:*",
          "s3:*",
          "s3-object-lambda:*",
          "ses:SendEmail",
          "cognito-idp:*",
          "secretsmanager:GetSecretValue",
          "backup:ListRecoveryPointsByBackupVault",
          "backup:DeleteRecoveryPoint"
        ]
        # 対象となるAWSリソースのARNの指定
        Resource = [
          "*"
        ]
      }
    ]
  })
  # ポリシーの説明文
  description = var.project_name
  # タグ
  tags = {
    ProjectName        = var.project_name
    ProjectStage       = local.project_stage
    ProjectDescription = var.project_description_tag
    ResourceCreatedBy  = "terraform"
  }
}

# IAMロールにポリシーを割り当て
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  # IAMロール名
  role = aws_iam_role.lambda_role.name
  # 割り当てるポリシーのARN
  policy_arn = aws_iam_policy.lambda_policy.arn
}


#============================================================
# AWS Backup関連のIAMロール
#============================================================

# IAMロールの設定
resource "aws_iam_role" "backup_role" {
  # IAMロール名
  name = "${var.project_name}-backup-${local.project_stage}"
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
    ProjectName        = var.project_name
    ProjectStage       = local.project_stage
    ProjectDescription = var.project_description_tag
    ResourceCreatedBy  = "terraform"
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
