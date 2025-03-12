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
    Name = var.project_name
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
    Name = var.project_name
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

# AWSマネージドのバックアップポリシー
data "aws_iam_policy" "aws_backup_service_role_policy_for_backup" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# IAMロールにポリシーを割り当て
resource "aws_iam_role_policy_attachment" "backup_policy" {
  # IAMロール
  role = aws_iam_role.backup_role.name
  # 割り当てるポリシーのARN
  policy_arn = data.aws_iam_policy.aws_backup_service_role_policy_for_backup.arn
}

# AWSマネージドのリストアポリシー
data "aws_iam_policy" "aws_backup_service_role_policy_for_restore" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# IAMロールにポリシーを割り当て
resource "aws_iam_role_policy_attachment" "backup_restore" {
  # IAMロール
  role = aws_iam_role.backup_role.name
  # 割り当てるポリシーのARN
  policy_arn = data.aws_iam_policy.aws_backup_service_role_policy_for_restore.arn
}
