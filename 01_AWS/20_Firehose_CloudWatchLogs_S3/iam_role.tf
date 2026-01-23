#============================================================
# IAMロール（Lambda）
#============================================================

# IAMロールの設定
resource "aws_iam_role" "lambda_role" {
  # IAMロール名
  name = "${var.project_name}-lambda-role"
  # IAMロールの対象となるAWSサービスの指定
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = ""
        Effect = "Allow"
        # LambdaにIAMロールを引き受けることを許可
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
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
  name = "${var.project_name}-lambda-policy"
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
          "s3-object-lambda:*"
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
# IAMロール（Firehose）
#============================================================

# IAMロールの設定
resource "aws_iam_role" "firehose_role" {
  # IAMロール名
  name = "${var.project_name}-firehose-role"
  # IAMロールの対象となるAWSサービスの指定
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      # FirehoseにIAMロールを引き受けることを許可
      Principal = {
        Service = "firehose.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
  # ポリシーの説明文
  description = var.project_name
  # タグ
  tags = {
    Name = var.project_name
  }
}

# IAMロールに紐付けるポリシーの設定
resource "aws_iam_role_policy" "firehose_policy" {
  # ポリシー割当先のIAMロール
  role = aws_iam_role.firehose_role.id
  # ポリシー(どのAWSリソースにどのような操作を許可するか)の定義
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        # 許可する操作の指定
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        # 対象となるAWSリソースのARNの指定
        Resource = [
          "${aws_s3_bucket.bucket_lambda_cloudwatch_log.arn}",
          "${aws_s3_bucket.bucket_lambda_cloudwatch_log.arn}/*"
        ]
      }
    ]
  })
}



#============================================================
# IAMロール（CloudWatch Logs）
#============================================================

# IAMロールの設定
resource "aws_iam_role" "lambda_cloudwatch_logs_role" {
  # IAMロール名
  name = "${var.project_name}-lambda-cloudwatch-logs-role"
  # IAMロールの対象となるAWSサービスの指定
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      # CloudWatch LogsにIAMロールを引き受けることを許可
      Principal = {
        Service = "logs.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# IAMロールに紐付けるポリシーの設定
resource "aws_iam_role_policy" "lambda_cloudwatch_logs_policy" {
  # ポリシー割当先のIAMロール
  role = aws_iam_role.lambda_cloudwatch_logs_role.id
  # ポリシー(どのAWSリソースにどのような操作を許可するか)の定義
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        # 許可する操作の指定
        Action = [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ]
        # 対象となるAWSリソースのARNの指定
        Resource = "${aws_kinesis_firehose_delivery_stream.lambda_cloudwatch_log_to_s3.arn}"
      }
    ]
  })
}

