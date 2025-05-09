#============================================================
# API Gateway
#============================================================

# REST APIの定義
resource "aws_api_gateway_rest_api" "api" {
  # API Gateway名
  name = "${var.project_name}-api-gateway-${local.project_stage}"
  # 説明文
  description = "${var.project_name} API Gateway ${local.project_stage}"
  # タグ
  tags = {
    Name = "${var.project_name}-api-gateway-${local.project_stage}"
  }
}

# API Gatewayのデプロイ設定
resource "aws_api_gateway_deployment" "deployment" {
  # 以下のリソースが生成されてから実行
  depends_on = [
    aws_api_gateway_integration.a_integration,
    aws_api_gateway_integration.b_integration
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
  stage_name = var.api_gateway_stage_name
  # API GatewayのRestAPIの定義ID
  rest_api_id = aws_api_gateway_rest_api.api.id
  # API Gatewayのデプロイ設定ID
  deployment_id = aws_api_gateway_deployment.deployment.id
  # ステージ名の説明
  description = "${var.project_name} API Gateway Stage ${local.project_stage}"
  # タグ
  tags = {
    Name = "${var.project_name}-api-gateway-stage-${local.project_stage}"
  }
}



# ==================== Lambda Web API A ====================

# REST APIのエンドポイントリソース定義（/a/{proxy+}）
resource "aws_api_gateway_resource" "a" {
  # 対象となるREST API定義のID
  rest_api_id = aws_api_gateway_rest_api.api.id
  # このリソースの親リソースのID
  # 最初の階層の場合は、ルートリソースID（aws_api_gateway_rest_api.<sample>.root_resource_id）を指定する。
  parent_id = aws_api_gateway_rest_api.api.root_resource_id
  # 受け付けるURLパスの設定
  path_part = "a"
}
resource "aws_api_gateway_resource" "a_proxy" {
  # 対象となるREST API定義のID
  rest_api_id = aws_api_gateway_rest_api.api.id
  # このリソースの親リソースのID
  parent_id = aws_api_gateway_resource.a.id
  # 受け付けるURLパスの設定
  # {proxy+}は任意のサブパスをまとめてすべてキャッチするワイルドカード
  # ここでは、/a/xxx, /a/yyy, /a/xxx/yyyなどのURLへのリクエストがこのエンドポイントにマッチするようになる。
  path_part = "{proxy+}"
}

# REST APIエンドポイントに追加するHTTPメソッドの定義
resource "aws_api_gateway_method" "a_any" {
  # 対象となるREST API定義のID
  rest_api_id = aws_api_gateway_rest_api.api.id
  # 対象となるREST APIエンドポイントの定義ID
  resource_id = aws_api_gateway_resource.a_proxy.id
  # 受け付けるメソッドの設定（ANY:任意のHTTPメソッド/POST/GET/PUT/DELETEなど）
  http_method = "ANY"
  # 認証の有無（NONE/AWS_IAM:IAM認証/COGNITO_USER_POOLS:Cognito認証/CUSTOM:カスタム認証）
  authorization = "NONE"
  # APIキーが必要なエンドポイントかどうか（false(default):不要）
  api_key_required = false
}

# Lambdaへの統合設定（REST APIの定義とLambdaの関連付け設定）
resource "aws_api_gateway_integration" "a_integration" {
  # 対象となるREST API定義のID
  rest_api_id = aws_api_gateway_rest_api.api.id
  # 対象となるREST APIエンドポイントの定義ID
  resource_id = aws_api_gateway_resource.a_proxy.id
  # 関連付けるHTTPメソッド（ANY:任意のHTTPメソッド/POST/GET/PUT/DELETEなど）
  http_method = aws_api_gateway_method.a_any.http_method
  # API Gatewayがバックエンドを呼び出す際のHTTPメソッド（Lambdaの場合は通常POST）
  integration_http_method = "POST"
  # 統合タイプ（AWS_PROXY/AWS/HTTP/MOCK）
  # AWS_PROXY: API GatewayのリクエストをそのままLambdaに渡す。
  type = "AWS_PROXY"
  # Lambdaの実行ARN
  uri = aws_lambda_function.lambda_web_api_a.invoke_arn
  # REST APIのタイムアウト値（ms）（最大29秒）
  timeout_milliseconds = 29000
}

# Lambda関数にAPI Gatewayからの実行権限を付与
resource "aws_lambda_permission" "apigw_a" {
  # 宣言ID
  statement_id = "AllowLambdaInvokeFromAPIGatewayA"
  # Lambda関数を実行するリソースのARN（ワイルドカードでリクエストパスを指定）
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/a/*"
  # 誰からのアクセスを許可するかの設定
  principal = "apigateway.amazonaws.com" # API Gatewayから
  # 許可アクションの設定
  action = "lambda:InvokeFunction" # Lambdaの呼び出し
  # 実行するLambda関数名
  function_name = aws_lambda_function.lambda_web_api_a.function_name
}

# API Gateway URLの表示
output "web_api_a_url" {
  value = "${aws_api_gateway_stage.stage.invoke_url}/a/test"
}



# ==================== Lambda Web API B ====================

# REST APIのエンドポイントリソース定義（/b/{proxy+}）
resource "aws_api_gateway_resource" "b" {
  # 対象となるREST API定義のID
  rest_api_id = aws_api_gateway_rest_api.api.id
  # このリソースの親リソースのID
  # 最初の階層の場合は、ルートリソースID（aws_api_gateway_rest_api.<sample>.root_resource_id）を指定する。
  parent_id = aws_api_gateway_rest_api.api.root_resource_id
  # 受け付けるURLパスの設定
  path_part = "b"
}
resource "aws_api_gateway_resource" "b_proxy" {
  # 対象となるREST API定義のID
  rest_api_id = aws_api_gateway_rest_api.api.id
  # このリソースの親リソースのID
  parent_id = aws_api_gateway_resource.b.id
  # 受け付けるURLパスの設定
  # {proxy+}は任意のサブパスをまとめてすべてキャッチするワイルドカード
  # ここでは、/b/xxx, /b/yyy, /b/xxx/yyyなどのURLへのリクエストがこのエンドポイントにマッチするようになる。
  path_part = "{proxy+}"
}

resource "aws_api_gateway_method" "b_any" {
  # 対象となるREST API定義のID
  rest_api_id = aws_api_gateway_rest_api.api.id
  # 対象となるREST APIエンドポイントの定義ID
  resource_id = aws_api_gateway_resource.b_proxy.id
  # 受け付けるメソッドの設定（ANY:任意のHTTPメソッド/POST/GET/PUT/DELETEなど）
  http_method = "ANY"
  # 認証の有無（NONE/AWS_IAM:IAM認証/COGNITO_USER_POOLS:Cognito認証/CUSTOM:カスタム認証）
  authorization = "NONE"
  # APIキーが必要なエンドポイントかどうか（false(default):不要）
  api_key_required = false
}

# Lambdaへの統合設定（REST APIの定義とLambdaの関連付け設定）
resource "aws_api_gateway_integration" "b_integration" {
  # 対象となるREST API定義のID
  rest_api_id = aws_api_gateway_rest_api.api.id
  # 対象となるREST APIエンドポイントの定義ID
  resource_id = aws_api_gateway_resource.b_proxy.id
  # 関連付けるHTTPメソッド（ANY:任意のHTTPメソッド/POST/GET/PUT/DELETEなど）
  http_method = aws_api_gateway_method.b_any.http_method
  # API Gatewayがバックエンドを呼び出す際のHTTPメソッド（Lambdaの場合は通常POST）
  integration_http_method = "POST"
  # 統合タイプ（AWS_PROXY/AWS/HTTP/MOCK）
  # AWS_PROXY: API GatewayのリクエストをそのままLambdaに渡す。
  type = "AWS_PROXY"
  # Lambdaの実行ARN
  uri = aws_lambda_function.lambda_web_api_b.invoke_arn
  # REST APIのタイムアウト値（ms）（最大29秒）
  timeout_milliseconds = 29000
}

# Lambda関数にAPI Gatewayからの実行権限を付与
resource "aws_lambda_permission" "apigw_b" {
  # 宣言ID
  statement_id = "AllowLambdaInvokeFromAPIGatewayB"
  # Lambda関数を実行するリソースのARN（ワイルドカードでリクエストパスを指定）
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/b/*"
  # 誰からのアクセスを許可するかの設定
  principal = "apigateway.amazonaws.com" # API Gatewayから
  # 許可アクションの設定
  action = "lambda:InvokeFunction" # Lambdaの呼び出し
  # 実行するLambda関数名
  function_name = aws_lambda_function.lambda_web_api_b.function_name
}

# API Gateway URLの表示
output "web_api_b_url" {
  value = "${aws_api_gateway_stage.stage.invoke_url}/b/test"
}
