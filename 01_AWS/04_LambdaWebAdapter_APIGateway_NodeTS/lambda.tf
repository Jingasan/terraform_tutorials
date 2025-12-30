#============================================================
# Lambda
#============================================================

# Lambda関数の設定
resource "aws_lambda_function" "lambda" {
  depends_on = [aws_ecr_repository.lambda]
  # 関数名
  function_name = "${var.project_name}-lambda-web-adapter-express-${local.lower_random_hex}"
  # Lambdaのデプロイパッケージタイプ（Zip:Lambda関数のZIPの場合（default）／Image:コンテナイメージの場合）
  package_type = "Image"
  # コンテナイメージのリポジトリのURI
  image_uri = "${aws_ecr_repository.lambda.repository_url}:latest"
  # 作成するLambda関数に対して許可するIAMロールの指定
  role = aws_iam_role.lambda_role.arn
  # Lambda関数のメモリサイズ（MB）（最小128MB，最大10,240MB）
  memory_size = var.lambda_memory_size
  # Lambda関数の一時ストレージ（/tmp領域）のサイズ（MB）（最小128MB，最大10,240MB）
  ephemeral_storage {
    # Lambda関数の一時ストレージサイズ（MB）（最小512MB、最大10,240MB）
    size = var.lambda_ephemeral_storage_size
  }
  # Lambda関数のタイムアウト時間
  timeout = var.lambda_timeout
  # 環境変数の指定
  environment {
    variables = {
      ENV_VAL  = "Terraform tutorial"
      NODE_ENV = "production"
      # Lambda Web AdapterはPORT=8080を自動認識
    }
  }
  # 作成するLambdaの説明文
  description = "${var.project_name}-lambda-web-adapter-express-${local.lower_random_hex}"
  # タグ
  tags = {
    Name = "${var.project_name}-lambda-web-adapter-express-${local.lower_random_hex}"
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
    Name = "${var.project_name}-lambda-web-adapter-express-${local.lower_random_hex}"
  }
}

# IAMロールの設定
resource "aws_iam_role" "lambda_role" {
  # IAMロール名
  name = "${var.project_name}-lambda-web-adapter-express-${local.lower_random_hex}"
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
  description = "${var.project_name}-lambda-web-adapter-express-${local.lower_random_hex}"
  # タグ
  tags = {
    Name = "${var.project_name}-lambda-web-adapter-express-${local.lower_random_hex}"
  }
}

# IAMロールに紐付けるポリシーの設定
resource "aws_iam_policy" "lambda_policy" {
  # ポリシー名
  name = "${var.project_name}-lambda-web-adapter-express-${local.lower_random_hex}"
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
  description = "${var.project_name}-lambda-web-adapter-express-${local.lower_random_hex}"
  # タグ
  tags = {
    Name = "${var.project_name}-lambda-web-adapter-express-${local.lower_random_hex}"
  }
}

# IAMロールにポリシーを割り当て
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
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
  name = "${var.project_name}-lambda-web-adapter-express-${local.lower_random_hex}"
  # API Gatewayのエンドポイントの設定
  endpoint_configuration {
    # API Gatewayのエンドポイントタイプ（EDGE(default):CloudFront/REGIONAL:リージョン/PRIVATE:VPC）
    # API Gatewayを自作のCloudFront経由で利用する場合は、REGIONALを指定する。
    #（EDGEにしておくと、API GatewayデフォルトのCloudFrontが作成される為、CloudFrontが二重になる）
    # API GatewayをVPC内からしかアクセスできないようにする場合は、PRIVATEを指定する。
    types = ["EDGE"]
  }
  # API Gatewayのデフォルトエンドポイントを無効化する（false(default):無効化しない）
  # 証明書をAPI Gatewayに直接設定し、独自ドメインを利用する場合に無効化する。
  disable_execute_api_endpoint = false
  # 説明文
  description = "${var.project_name}-lambda-web-adapter-express-${local.lower_random_hex}"
  # タグ
  tags = {
    Name = "${var.project_name}-lambda-web-adapter-express-${local.lower_random_hex}"
  }
}

# API Gateway V1の定義
resource "aws_api_gateway_resource" "proxy" {
  # 対象となるREST API定義のID
  rest_api_id = aws_api_gateway_rest_api.api.id
  # このリソースの親リソースのID
  # 最初の階層の場合は、ルートリソースID（aws_api_gateway_rest_api.<sample>.root_resource_id）を指定する。
  parent_id = aws_api_gateway_rest_api.api.root_resource_id
  # 受け付けるURLパスの設定
  path_part = "{proxy+}" # 任意のリクエストパスを受け付ける
}

# REST APIエンドポイントに追加するHTTPメソッドの定義
resource "aws_api_gateway_method" "proxy" {
  # 対象となるREST API定義のID
  rest_api_id = aws_api_gateway_rest_api.api.id
  # 対象となるREST APIエンドポイントの定義ID
  resource_id = aws_api_gateway_resource.proxy.id
  # 受け付けるメソッドの設定（ANY:任意のHTTPメソッド/POST/GET/PUT/DELETEなど）
  http_method = "ANY"
  # 認証の有無（NONE/AWS_IAM:IAM認証/COGNITO_USER_POOLS:Cognito認証/CUSTOM:カスタム認証）
  authorization = "NONE"
  # APIキーが必要なエンドポイントかどうか（false(default):不要）
  api_key_required = false
}

# API GatewayからのLambda呼び出し設定
resource "aws_api_gateway_integration" "lambda" {
  # 対象となるREST API定義のID
  rest_api_id = aws_api_gateway_rest_api.api.id
  # 対象となるREST APIエンドポイントの定義ID
  resource_id = aws_api_gateway_method.proxy.resource_id
  # 関連付けるHTTPメソッド（ANY:任意のHTTPメソッド/POST/GET/PUT/DELETEなど）
  http_method = aws_api_gateway_method.proxy.http_method
  # API Gatewayがバックエンドを呼び出す際のHTTPメソッド（Lambdaの場合は通常POST）
  integration_http_method = "POST"
  # 統合タイプ（AWS_PROXY/AWS/HTTP/MOCK）
  # AWS_PROXY: API GatewayのリクエストをそのままLambdaに渡す。
  type = "AWS_PROXY"
  # Lambdaの実行ARN
  uri = aws_lambda_function.lambda.invoke_arn
  # REST APIのタイムアウト値（ms）（最大29秒）
  timeout_milliseconds = 29000
}

# APIルートパスに許可するHTTPメソッドの設定
# {proxy+}はAPIのルートパスだけ受け付けないため、別途定義
resource "aws_api_gateway_method" "proxy_root" {
  # 対象となるREST API定義のID
  rest_api_id = aws_api_gateway_rest_api.api.id
  # 対象となるREST APIエンドポイントの定義ID
  resource_id = aws_api_gateway_rest_api.api.root_resource_id
  # 受け付けるメソッドの設定（ANY:任意のHTTPメソッド/POST/GET/PUT/DELETEなど）
  http_method = "ANY"
  # 認証の有無（NONE/AWS_IAM:IAM認証/COGNITO_USER_POOLS:Cognito認証/CUSTOM:カスタム認証）
  authorization = "NONE"
  # APIキーが必要なエンドポイントかどうか（false(default):不要）
  api_key_required = false
}

# API GatewayからのLambda呼び出し設定(APIルートパス用)
resource "aws_api_gateway_integration" "lambda_root" {
  # 対象となるREST API定義のID
  rest_api_id = aws_api_gateway_rest_api.api.id
  # 対象となるREST APIエンドポイントの定義ID
  resource_id = aws_api_gateway_method.proxy_root.resource_id
  # 関連付けるHTTPメソッド（ANY:任意のHTTPメソッド/POST/GET/PUT/DELETEなど）
  http_method = aws_api_gateway_method.proxy_root.http_method
  # API Gatewayがバックエンドを呼び出す際のHTTPメソッド（Lambdaの場合は通常POST）
  integration_http_method = "POST"
  # 統合タイプ（AWS_PROXY/AWS/HTTP/MOCK）
  # AWS_PROXY: API GatewayのリクエストをそのままLambdaに渡す。
  type = "AWS_PROXY"
  # Lambdaの実行ARN
  uri = aws_lambda_function.lambda.invoke_arn
  # REST APIのタイムアウト値（ms）（最大29秒）
  timeout_milliseconds = 29000
}

# API Gatewayのデプロイ設定
resource "aws_api_gateway_deployment" "api_gateway" {
  # Rest APIの設定ID
  rest_api_id = aws_api_gateway_rest_api.api.id
  # 以下のリソースが生成されてから実行 
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_root,
  ]
  # 説明
  description = "${var.project_name}-lambda-web-adapter-express-${local.lower_random_hex}"
  # 既存のAPI Gatewayリソースがあった場合に一旦削除してから作り直す設定
  lifecycle {
    create_before_destroy = true
  }
}

# API Gatewayステージ名の設定
resource "aws_api_gateway_stage" "api_gateway_stage" {
  # ステージ名
  stage_name = var.apigateway_stage_name
  # ステージ名の説明
  description = "${var.project_name}-lambda-web-adapter-express-${local.lower_random_hex}"
  # RestAPIの定義ID
  rest_api_id = aws_api_gateway_rest_api.api.id
  # API Gatewayのデプロイ設定ID
  deployment_id = aws_api_gateway_deployment.api_gateway.id
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
  value       = aws_api_gateway_stage.api_gateway_stage.invoke_url
}
