#============================================================
# S3：ビルドしたLambda関数zipファイルをデプロイするバケットの設定
#============================================================

# Lambda関数のzipファイルをデプロイするS3バケットの設定
resource "aws_s3_bucket" "lambda_bucket" {
  # バケット名
  bucket = "${var.project_name}-lambda-${local.lower_random_hex}"
  # バケットの中にオブジェクトが入っていてもTerraformに削除を許可するかどうか(true:許可)
  force_destroy = true
  # タグ
  tags = {
    Name = var.project_name
  }
}

# Lambda関数のzip化の設定
data "archive_file" "lambda" {
  type = "zip"
  # zip化対象のディレクトリ
  source_dir = "${path.module}/src"
  # zipファイルの出力先
  output_path = "${path.module}/.lambda/lambda.zip"
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

# Lambdaバケット名のコンソール出力
output "lambda_bucket_name" {
  description = "Lambda関数のコードを保管するS3バケット名"
  value       = aws_s3_bucket.lambda_bucket.id
}



#============================================================
# Lambda
#============================================================

# Lambda関数の設定
resource "aws_lambda_function" "lambda" {
  # 関数名
  function_name = var.project_name
  # 実行環境の指定(ex: nodejs, python, go, etc.)
  runtime = var.lambda_runtime
  # ハンドラの指定
  handler = "index.handler"
  # 作成するLambda関数に対して許可するIAMロールの指定
  role = aws_iam_role.lambda_role.arn
  # Lambda関数のコード取得元S3バケットとパス
  s3_bucket = aws_s3_bucket.lambda_bucket.bucket
  s3_key    = aws_s3_object.lambda_zip_uploader.key
  # ソースコードが変更されていたら再デプロイする設定
  source_code_hash = data.archive_file.lambda.output_base64sha256
  # Lambda関数のタイムアウト時間
  timeout = var.lambda_timeout
  # 環境変数の指定
  environment {
    variables = {
      ENV_VAL = "Terraform tutorial"
    }
  }
  # 作成するLambdaの説明文
  description = var.project_name
  # タグ
  tags = {
    Name = var.project_name
  }
}

# CloudWatchロググループの設定
resource "aws_cloudwatch_log_group" "lambda" {
  # CloudWatchロググループ名
  name = "/aws/lambda/${aws_lambda_function.lambda.function_name}"
  # ログを残す期間(日)の指定
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
resource "aws_iam_role_policy_attachment" "lambda" {
  # IAMロール名
  role = aws_iam_role.lambda_role.name
  # 割り当てるポリシーのARN
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Lambda関数名のコンソール出力
output "function_name" {
  description = "Lambda関数名"
  value       = aws_lambda_function.lambda.function_name
}



#============================================================
# API Gateway
#============================================================

# RestAPIの定義
resource "aws_api_gateway_rest_api" "api" {
  # API Gateway名
  name = var.project_name
  # 説明文
  description = var.project_name
  # タグ
  tags = {
    Name = var.project_name
  }
}

# API Gateway V1の定義
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  # 受け付けるURLパスの設定
  path_part = "{proxy+}" # 任意のリクエストパスを受け付ける
}

# 許可するHTTPメソッドの設定
resource "aws_api_gateway_method" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.proxy.id
  # 受け付けるメソッドの設定
  http_method = "ANY" # 任意のHTTPメソッドを受け付ける
  # 認証の有無
  authorization = "NONE"
}

# API GatewayからのLambda呼び出し設定
resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_method.proxy.resource_id
  http_method             = aws_api_gateway_method.proxy.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

# APIルートパスに許可するHTTPメソッドの設定
# {proxy+}はAPIのルートパスだけ受け付けないため、別途定義
resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_rest_api.api.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

# API GatewayからのLambda呼び出し設定(APIルートパス用)
resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_method.proxy_root.resource_id
  http_method             = aws_api_gateway_method.proxy_root.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

# API Gatewayのデプロイ設定
resource "aws_api_gateway_deployment" "api_gateway" {
  # Rest APIの設定ID
  rest_api_id = aws_api_gateway_rest_api.api.id
  # ステージ名
  stage_name = var.apigateway_stage_name
  # 以下のリソースが生成されてから実行 
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_root,
  ]
  # ステージ名の説明
  stage_description = var.project_name
  # 既存のAPI Gatewayリソースがあった場合に一旦削除してから作り直す設定
  lifecycle {
    create_before_destroy = true
  }
}

# API GatewayがLambdaにアクセスできるようにする設定
resource "aws_lambda_permission" "api_gateway" {
  # アクセスを許可するLambda関数名の指定
  function_name = aws_lambda_function.lambda.function_name
  # 任意の名称を指定
  statement_id = "AllowAPIGatewayInvoke"
  # 誰からのアクセスを許可するかの設定
  principal = "apigateway.amazonaws.com" # API Gatewayから
  # 許可するアクションの設定
  action = "lambda:InvokeFunction" # Lambdaの呼び出し
  # どのようなリクエストパスでのアクセスも許可
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

# API URLのコンソール出力
output "base_url" {
  description = "API URL"
  value       = aws_api_gateway_deployment.api_gateway.invoke_url
}
