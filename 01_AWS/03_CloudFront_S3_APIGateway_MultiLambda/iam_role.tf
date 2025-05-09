#============================================================
# IAMロール（Lambda）
#============================================================

# IAMロールの設定
resource "aws_iam_role" "lambda_role" {
  # IAMロール名
  name = "${var.project_name}-lambda-iam-role-${local.project_stage}"
  # IAMロールの対象となるAWSサービスの指定
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        # LambdaにIAMロールを引き受けることを許可
        Principal = {
          Service = ["lambda.amazonaws.com"]
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
  # 説明
  description = "${var.project_name} Lambda IAM Role ${local.project_stage}"
  # タグ
  tags = {
    Name = "${var.project_name}-lambda-iam-role-${local.project_stage}"
  }
}

# IAMロールに紐付けるポリシーの設定
resource "aws_iam_policy" "lambda_policy" {
  # ポリシー名
  name = "${var.project_name}-lambda-iam-policy-${local.project_stage}"
  # ポリシー(どのAWSリソースにどのような操作を許可するか)の定義
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        # 許可する操作の指定
        Action = [
          "ec2:*",              # EC2関連のすべての操作権限
          "ecs:*",              # ECS関連のすべての操作権限
          "logs:*",             # CloudWatch Logs関連のすべての操作権限
          "s3:*",               # S3関連のすべての操作権限
          "s3-object-lambda:*", # S3 Object Lambda関連のすべての操作権限
          "ssm:*",              # SSM関連のすべての操作権限
        ]
        # 対象となるAWSリソースのARNの指定
        Resource = [
          "*"
        ]
      }
    ]
  })
  # ポリシーの説明文
  description = "${var.project_name} Lambda IAM Policy for ${local.project_stage}"
  # タグ
  tags = {
    Name = "${var.project_name}-lambda-iam-policy-${local.project_stage}"
  }
}

# IAMロールにポリシーを割り当て
resource "aws_iam_role_policy_attachment" "lambda" {
  # IAMロール名
  role = aws_iam_role.lambda_role.name
  # 割り当てるポリシーのARN
  policy_arn = aws_iam_policy.lambda_policy.arn
}
