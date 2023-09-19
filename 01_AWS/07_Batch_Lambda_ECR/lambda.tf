#============================================================
# S3：ビルドしたLambda関数zipファイルをデプロイするバケットの設定
#============================================================

# Lambda関数のzipファイルをデプロイするS3バケットの設定
resource "aws_s3_bucket" "lambda_bucket" {
  # S3バケット名
  bucket = "${var.project_name}-lambdazip-bucket"
  # バケットの中にオブジェクトが入っていてもTerraformに削除を許可するかどうか(true:許可)
  force_destroy = true
  # タグ
  tags = {
    Name = var.project_name
  }
}



#============================================================
# Lambda
#============================================================

# Lambda関数の設定
resource "aws_lambda_function" "lambda" {
  # 関数のZIPファイルをS3にアップロードした後に実行
  depends_on = [null_resource.lambda_build_upload]
  # 関数名
  function_name = "${var.project_name}-func"
  # 実行ランタイム（ex: nodejs, python, go, etc.）
  runtime = var.lambda_runtime
  # ハンドラの指定
  handler = "index.handler"
  # 作成するLambda関数に対して許可するIAMロールの指定
  role = aws_iam_role.lambda_role.arn
  # Lambda関数のコード取得元S3バケットとパス
  s3_bucket = aws_s3_bucket.lambda_bucket.bucket
  s3_key    = "lambda.zip"
  # Lambda関数のタイムアウト時間
  timeout = var.lambda_timeout
  # 作成するLambdaの説明文
  description = "${var.project_name} lambda function"
  # 環境変数の指定
  environment {
    variables = {
      JOB_QUEUE      = "${aws_batch_job_queue.job_queue.name}"           # ジョブキュー
      JOB_DEFINITION = "${aws_batch_job_definition.job_definition.name}" # ジョブ定義
    }
  }
  # Lambda関数をVPCに所属させる設定
  vpc_config {
    # サブネット
    subnet_ids = [for value in aws_subnet.private : value.id]
    # セキュリティグループ
    security_group_ids = [aws_security_group.batch.id]
  }
  # タグ
  tags = {
    Name = var.project_name
  }
}

# Lambda関数のローカルビルドコマンドの設定
resource "null_resource" "lambda_build_upload" {
  # ビルド済みの関数zipファイルアップロード先のS3バケットが生成されたら実行
  depends_on = [aws_s3_bucket.lambda_bucket]
  # ソースコードに差分があった場合に実行
  triggers = {
    code_diff = join("", [
      for file in fileset("lambda/src", "{*.ts, package*.json}")
      : filebase64("lambda/src/${file}")
    ])
    package_diff = join("", [
      for file in fileset("lambda", "{package*.json}")
      : filebase64("lambda/${file}")
    ])
  }
  # Lambda関数依存パッケージのインストール
  provisioner "local-exec" {
    # 実行するコマンド
    command = "npm install"
    # コマンドを実行するディレクトリ
    working_dir = "lambda"
  }
  # Lambda関数のビルド
  provisioner "local-exec" {
    command     = "npm run build"
    working_dir = "lambda"
  }
  # Lambda関数のZIP圧縮
  provisioner "local-exec" {
    command     = "zip lambda.zip index.js"
    working_dir = "lambda/dist"
  }
  # S3アップロード
  provisioner "local-exec" {
    command     = "aws s3 cp ./dist/lambda.zip s3://${aws_s3_bucket.lambda_bucket.bucket}/lambda.zip"
    working_dir = "lambda"
  }
}

# Lambda関数の更新
resource "null_resource" "lambda_update" {
  # Lambda関数作成後に実行
  depends_on = [null_resource.lambda_build_upload, aws_lambda_function.lambda]
  # ソースコードに差分があった場合にのみ実行
  triggers = {
    code_diff = join("", [
      for file in fileset("lambda/src", "{*.ts}")
      : filebase64("lambda/src/${file}")
    ])
    package_diff = join("", [
      for file in fileset("lambda", "{package*.json}")
      : filebase64("lambda/${file}")
    ])
  }
  # Lambda関数を更新
  provisioner "local-exec" {
    command     = "aws lambda update-function-code --function-name ${aws_lambda_function.lambda.function_name} --s3-bucket ${aws_s3_bucket.lambda_bucket.bucket} --s3-key lambda.zip --publish --no-cli-pager"
    working_dir = "lambda"
  }
}

# CloudWatchロググループの設定
resource "aws_cloudwatch_log_group" "lambda" {
  # CloudWatchロググループ名
  name = "/aws/lambda/${aws_lambda_function.lambda.function_name}"
  # CloudWatchにログを残す期間（日）
  retention_in_days = var.lambda_cloudwatch_log_retention_in_days
  # タグ
  tags = {
    Name = var.project_name
  }
}

# IAMロールの設定
resource "aws_iam_role" "lambda_role" {
  # IAMロール名
  name = "${var.project_name}-lambda-iam-role"
  # IAMロールにポリシーを紐付け
  managed_policy_arns = [
    aws_iam_policy.lambda_policy.arn
  ]
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
  description = "Lambda IAM Role for ${var.project_name}"
  # タグ
  tags = {
    Name = var.project_name
  }
}

# IAMロールに紐付けるポリシーの設定
resource "aws_iam_policy" "lambda_policy" {
  # ポリシー名
  name = "${var.project_name}-lambda-iam-policy"
  # ポリシーの説明文
  description = "Lambda IAM Policy for ${var.project_name}"
  # ポリシー(どのAWSリソースにどのような操作を許可するか)の定義
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        # 許可する操作の指定
        Action = [
          "s3:*",               # S3関連のすべての操作権限
          "s3-object-lambda:*", # S3 Object Lambda関連のすべての操作権限
          "ec2:*",              # EC2関連のすべての操作権限
          "ecs:*",              # ECS関連のすべての操作権限
          "batch:*",            # Batch関連のすべての操作権限
          "rds:*",              # RDS関連のすべての操作権限
          "secretsmanager:*",   # Secrets Manager関連のすべての操作権限
          "logs:*",             # CloudWatch Logs関連のすべての操作権限
        ]
        # 対象となるAWSリソースのARNの指定
        Resource = [
          "*"
        ]
      }
    ]
  })
  # タグ
  tags = {
    Name = var.project_name
  }
}

# CloudFront向けにLambda関数のURLを定義
resource "aws_lambda_function_url" "lambda" {
  function_name      = aws_lambda_function.lambda.function_name
  authorization_type = "NONE"
}

# Lambda関数URL
output "function_url" {
  description = "Lambda関数URL"
  value       = "${aws_lambda_function_url.lambda.function_url}job"
}
