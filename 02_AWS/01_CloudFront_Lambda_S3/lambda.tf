#============================================================
# S3：ビルドしたLambda関数zipファイルをデプロイするバケットの設定
#============================================================

# Lambda関数のzipファイルをデプロイするS3バケットの設定
resource "aws_s3_bucket" "lambda_bucket" {
  # S3バケット名
  bucket = var.lambda_bucket_name
  # バケットの中にオブジェクトが入っていてもTerraformに削除を許可するかどうか(true:許可)
  force_destroy = true
  # タグ
  tags = {
    Name = var.tag_name
  }
}

# Lambda関数のzip化の設定
data "archive_file" "lambda" {
  # Lambda関数のビルド後に実行
  depends_on = [null_resource.lambda_build]
  # 生成するアーカイブの種類
  type = "zip"
  # zip化対象のディレクトリ
  source_dir = "${path.module}/node/dist"
  # zipファイルの出力先
  output_path = "${path.module}/node/.lambda/lambda.zip"
}

# Lambda関数のアップロード設定
resource "aws_s3_object" "lambda_zip_uploader" {
  # アップロード先バケット
  bucket = aws_s3_bucket.lambda_bucket.id
  # アップロード先のパス
  key = "lambda.zip"
  # アップロード対象の指定
  source = data.archive_file.lambda.output_path
  # アップロード対象に変更があった場合にのみアップロードする設定
  etag = filemd5(data.archive_file.lambda.output_path)
}



#============================================================
# Lambda
#============================================================

# Lambda関数の設定
resource "aws_lambda_function" "lambda" {
  # 関数名
  function_name = var.lambda_name
  # 実行環境の指定(ex: nodejs, python, go, etc.)
  runtime = "nodejs16.x"
  # ハンドラの指定
  handler = "index.handler"
  # 作成するLambda関数に対して許可するIAMロールの指定
  role = aws_iam_role.lambda_role.arn
  # Lambda関数のコード取得元S3バケットとパス
  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_zip_uploader.key
  # ソースコードが変更されていたら再デプロイする設定
  source_code_hash = data.archive_file.lambda.output_base64sha256
  # Lambda関数のタイムアウト時間
  timeout = 30
  # 作成するLambdaの説明文
  description = var.tag_name
  # 環境変数の指定
  environment {
    variables = {
      ENV_VAL = "Terraform tutorial"
    }
  }
  # タグ
  tags = {
    Name = var.tag_name
  }
}

# Lambda関数のローカルビルドコマンドの設定
resource "null_resource" "lambda_build" {
  # ビルド済みの関数zipファイルアップロード先のS3バケットが生成されたら実行
  depends_on = [aws_s3_bucket.lambda_bucket]
  # Lambda関数依存パッケージのインストール
  provisioner "local-exec" {
    # 実行するコマンド
    command = "npm install"
    # コマンドを実行するディレクトリ
    working_dir = "node"
  }
  # Lambda関数のビルド
  provisioner "local-exec" {
    command     = "npm run build"
    working_dir = "node"
  }
}

# CloudWatchロググループの設定
resource "aws_cloudwatch_log_group" "lambda" {
  # CloudWatchロググループ名
  name = "/aws/lambda/${aws_lambda_function.lambda.function_name}"
  # ログを残す期間(日)の指定
  retention_in_days = 30
  # タグ
  tags = {
    Name = var.tag_name
  }
}

# IAMロールの設定
resource "aws_iam_role" "lambda_role" {
  # IAMロール名
  name = var.iam_role_name
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
  # タグ
  tags = {
    Name = var.tag_name
  }
}

# IAMロールに紐付けるポリシーの設定
resource "aws_iam_policy" "lambda_policy" {
  # ポリシー名
  name = var.iam_policy_name
  # ポリシーの説明文
  description = var.tag_name
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
  # タグ
  tags = {
    Name = var.tag_name
  }
}

# Lambda関数のURLリソースの設定
resource "aws_lambda_function_url" "lambda" {
  function_name      = aws_lambda_function.lambda.function_name
  authorization_type = "NONE"
}

# Lambda関数URL
output "lambda_function_url" {
  description = "Lambda関数URL"
  value       = aws_lambda_function_url.lambda.function_url
}
