#============================================================
# Lambda
#============================================================

# Lambda関数の設定
resource "aws_lambda_function" "lambda" {
  # 関数のZIPファイルをS3にアップロードした後に実行
  depends_on = [null_resource.lambda_build_upload]
  # 関数名
  function_name = var.project_name
  # 実行環境の指定(ex: nodejs, python, go, etc.)
  runtime = var.lambda_runtime
  # ハンドラの指定
  handler = "dist/index.handler"
  # 作成するLambda関数に対して許可するIAMロールの指定
  role = aws_iam_role.lambda_role.arn
  # Lambda関数のコード取得元S3バケットとパス
  s3_bucket = aws_s3_bucket.bucket_lambda.bucket
  s3_key    = "lambda.zip"
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

# Lambda関数のビルドとS3アップロード
resource "null_resource" "lambda_build_upload" {
  # ビルド済み関数ZIPのアップロード先S3バケットが生成されたら実行
  depends_on = [aws_s3_bucket.bucket_lambda]
  # ソースコードに差分があった場合に実行
  triggers = {
    code_diff = join("", [
      for file in fileset("node/src", "{*.mts}")
      : filebase64("node/src/${file}")
    ])
    package_diff = join("", [
      for file in fileset("node", "{package*.json}")
      : filebase64("node/${file}")
    ])
  }
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
  # Lambda関数のZIP圧縮
  provisioner "local-exec" {
    command     = "zip -r lambda.zip dist node_modules public"
    working_dir = "node"
  }
  # S3アップロード
  provisioner "local-exec" {
    command     = "aws s3 cp --profile ${var.profile} lambda.zip s3://${aws_s3_bucket.bucket_lambda.bucket}/lambda.zip"
    working_dir = "node"
  }
}

# Lambda関数の更新
resource "null_resource" "lambda_update" {
  # Lambda関数作成後に実行
  depends_on = [null_resource.lambda_build_upload, aws_lambda_function.lambda]
  # ソースコードに差分があった場合にのみ実行
  triggers = {
    code_diff = join("", [
      for file in fileset("node/src", "{*.mts}")
      : filebase64("node/src/${file}")
    ])
    package_diff = join("", [
      for file in fileset("node", "{package*.json}")
      : filebase64("node/${file}")
    ])
  }
  # Lambda関数を更新
  provisioner "local-exec" {
    command     = "aws lambda update-function-code --profile ${var.profile} --function-name ${aws_lambda_function.lambda.function_name} --s3-bucket ${aws_s3_bucket.bucket_lambda.bucket} --s3-key lambda.zip --publish --no-cli-pager"
    working_dir = "node"
  }
}



#============================================================
# CloudWatch Logs
#============================================================

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

# CloudWatch Logsのログ転送フィルタの設定
#（CloudWatch Logsのログを出力と同時にKinesis Data Firehose経由でS3に即座に転送する）
resource "aws_cloudwatch_log_subscription_filter" "lambda_to_s3" {
  # サブスクリプションフィルタ名
  name = "${var.project_name}-lambda-logs-to-s3"
  # 対象となるCloudWatchロググループ名（サブスクリプションフィルタはロググループごとに2個までしか設定できないため、注意）
  log_group_name = aws_cloudwatch_log_group.lambda.name
  # フィルタパターン
  filter_pattern = "" # すべてのログを送信対象とする
  # 送信先のARN
  destination_arn = aws_kinesis_firehose_delivery_stream.lambda_cloudwatch_log_to_s3.arn # S3バケットを指定
  # サブスクリプションフィルタの実行に使用するIAMロールのARN
  role_arn = aws_iam_role.lambda_cloudwatch_logs_role.arn
}



#============================================================
# API Gateway
#============================================================

# RestAPIの定義
resource "aws_api_gateway_rest_api" "api" {
  # API Gateway名
  name = var.project_name
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
  description = var.project_name
  # タグ
  tags = {
    Name = var.project_name
  }
}

# REST APIのエンドポイントリソース定義
resource "aws_api_gateway_resource" "proxy" {
  # 対象となるREST API定義のID
  rest_api_id = aws_api_gateway_rest_api.api.id
  # このリソースの親リソースのID
  # 最初の階層の場合は、ルートリソースID
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
  timeout_milliseconds = 29000
}

# REST APIエンドポイントに追加するHTTPメソッドの定義
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

# Lambdaへの統合設定（REST APIの定義とLambdaの関連付け設定）(APIルートパス用)
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
  description = var.project_name
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
  description = var.project_name
  # RestAPIの定義ID
  rest_api_id = aws_api_gateway_rest_api.api.id
  # API Gatewayのデプロイ設定ID
  deployment_id = aws_api_gateway_deployment.api_gateway.id
}

# Lambda関数にAPI Gatewayからの実行権限を付与
resource "aws_lambda_permission" "api_gateway" {
  # 宣言ID
  statement_id = "${var.project_name}-allow-lambda-invoke-from-lgwan-api-gateway"
  # Lambda関数を実行するリソースのARN（ワイルドカードでリクエストパスを指定）
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
  # 誰からのアクセスを許可するかの設定
  principal = "apigateway.amazonaws.com" # API Gatewayから
  # 許可するアクションの設定
  action = "lambda:InvokeFunction" # Lambdaの呼び出し
  # 実行するLambda関数名
  function_name = aws_lambda_function.lambda.function_name
}

# API URLのコンソール出力
output "base_url" {
  description = "API URL"
  value       = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_stage.api_gateway_stage.stage_name}"
}
