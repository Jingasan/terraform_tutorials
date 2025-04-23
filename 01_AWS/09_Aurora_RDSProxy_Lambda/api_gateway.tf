#============================================================
# API Gateway
#============================================================

# REST APIの定義
resource "aws_api_gateway_rest_api" "api" {
  # API Gateway名
  name = "${var.project_name}-api-gateway"
  # 説明文
  description = var.project_name
  # タグ
  tags = {
    Name              = "${var.project_name}-aurora-postgresql"
    ProjectName       = var.project_name
    ResourceCreatedBy = "terraform"
  }
}

# REST APIのエンドポイントリソース定義
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

# Lambdaへの統合設定（REST APIの定義とLambdaの関連付け設定）
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
  timeout_milliseconds = var.api_gateway_timeout_milliseconds
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
  # 以下のリソースが生成されてから実行 
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_root,
  ]
  # Rest APIの設定ID
  rest_api_id = aws_api_gateway_rest_api.api.id
  # 説明
  description = var.project_name
  # 既存のAPI Gatewayリソースがあった場合に一旦削除してから作り直す設定
  lifecycle {
    create_before_destroy = true
  }
}

# REST APIのステージ（APIバージョンなど）の設定
resource "aws_api_gateway_stage" "stage" {
  # REST APIのステージ名（APIバージョン）（例：dev/prod/v1/v2）
  stage_name = "dev"
  # API GatewayのRestAPIの定義ID
  rest_api_id = aws_api_gateway_rest_api.api.id
  # API Gatewayのデプロイ設定ID
  deployment_id = aws_api_gateway_deployment.api_gateway.id
  # ステージ名の説明
  description = "${var.project_name} api gateway stage"
  # タグ
  tags = {
    Name              = var.project_name
    ProjectName       = var.project_name
    ResourceCreatedBy = "terraform"
  }
}

# Lambda関数にAPI Gatewayからの実行権限を付与
resource "aws_lambda_permission" "api_gateway" {
  # 宣言ID
  statement_id = "AllowAPIGatewayInvoke"
  # Lambda関数を実行するリソースのARN（どのようなリクエストパスでのアクセスも許可）
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
  # 誰からのアクセスを許可するかの設定
  principal = "apigateway.amazonaws.com" # API Gatewayから
  # 許可アクションの設定
  action = "lambda:InvokeFunction" # Lambdaの呼び出し
  # 実行するLambda関数名
  function_name = aws_lambda_function.lambda.function_name
}

# API URLのコンソール出力
output "api_gateway_url" {
  description = "API URL"
  value       = aws_api_gateway_stage.stage.invoke_url
}
