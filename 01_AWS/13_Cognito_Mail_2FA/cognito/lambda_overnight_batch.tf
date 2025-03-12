#============================================================
# S3：ビルドしたLambda関数zipファイルをデプロイするバケットの設定
#============================================================

# Lambda関数のzipファイルをデプロイするS3バケットの設定
resource "aws_s3_bucket" "bucket_lambda_overnight_batch" {
  # S3バケット名
  bucket = "${var.project_name}-lambda-overnight-batch-${local.lower_random_hex}"
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
resource "aws_lambda_function" "lambda_overnight_batch" {
  # 関数のZIPファイルをS3にアップロードした後に実行
  depends_on = [null_resource.build_upload_lambda_overnight_batch]
  # 関数名
  function_name = "${var.project_name}-overnight-batch"
  # 実行環境の指定(ex: nodejs, python, go, etc.)
  runtime = var.lambda_runtime
  # ハンドラの指定
  handler = "dist/index.handler"
  # 作成するLambda関数に対して許可するIAMロールの指定
  role = aws_iam_role.lambda_role.arn
  # Lambda関数のコード取得元S3バケットとパス
  s3_bucket = aws_s3_bucket.bucket_lambda_overnight_batch.bucket
  s3_key    = "lambda.zip"
  # Lambda関数のタイムアウト時間
  timeout = var.lambda_timeout
  # 環境変数の指定
  environment {
    variables = {
      SERVICE_NAME   = var.project_name
      REGION         = var.region
      SES_EMAIL_FROM = var.cognito_from_email_address
      SECRET_NAME    = aws_secretsmanager_secret.secretsmanager.name
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
resource "null_resource" "build_upload_lambda_overnight_batch" {
  # ビルド済み関数ZIPのアップロード先S3バケットが生成されたら実行
  depends_on = [aws_s3_bucket.bucket_lambda_overnight_batch]
  # ソースコードに差分があった場合に実行
  triggers = {
    code_diff = join("", [
      for file in fileset("lambda_overnight_batch/src", "{*.mts}")
      : filebase64("lambda_overnight_batch/src/${file}")
    ])
    package_diff = join("", [
      for file in fileset("lambda_overnight_batch", "{package*.json}")
      : filebase64("lambda_overnight_batch/${file}")
    ])
  }
  # Lambda関数依存パッケージのインストール
  provisioner "local-exec" {
    # 実行するコマンド
    command = "npm install"
    # コマンドを実行するディレクトリ
    working_dir = "lambda_overnight_batch"
  }
  # Lambda関数のビルド
  provisioner "local-exec" {
    command     = "npm run build"
    working_dir = "lambda_overnight_batch"
  }
  # Lambda関数のZIP圧縮
  provisioner "local-exec" {
    command     = "zip -r lambda.zip dist node_modules"
    working_dir = "lambda_overnight_batch"
  }
  # S3アップロード
  provisioner "local-exec" {
    command     = "aws s3 cp lambda.zip s3://${aws_s3_bucket.bucket_lambda_overnight_batch.bucket}/lambda.zip"
    working_dir = "lambda_overnight_batch"
  }
}

# Lambda関数の更新
resource "null_resource" "update_lambda_overnight_batch" {
  # Lambda関数作成後に実行
  depends_on = [null_resource.build_upload_lambda_overnight_batch, aws_lambda_function.lambda_overnight_batch]
  # ソースコードに差分があった場合にのみ実行
  triggers = {
    code_diff = join("", [
      for file in fileset("lambda_overnight_batch/src", "{*.mts}")
      : filebase64("lambda_overnight_batch/src/${file}")
    ])
    package_diff = join("", [
      for file in fileset("lambda_overnight_batch", "{package*.json}")
      : filebase64("lambda_overnight_batch/${file}")
    ])
  }
  # Lambda関数を更新
  provisioner "local-exec" {
    command     = "aws lambda update-function-code --function-name ${aws_lambda_function.lambda_overnight_batch.function_name} --s3-bucket ${aws_s3_bucket.bucket_lambda_overnight_batch.bucket} --s3-key lambda.zip --publish --no-cli-pager"
    working_dir = "lambda_overnight_batch"
  }
}

# CloudWatchロググループの設定
resource "aws_cloudwatch_log_group" "lambda_overnight_batch" {
  # CloudWatchロググループ名
  name = "/aws/lambda/${aws_lambda_function.lambda_overnight_batch.function_name}"
  # ログを残す期間(日)の指定
  retention_in_days = var.lambda_cloudwatch_log_retention_in_days
  # タグ
  tags = {
    Name = var.project_name
  }
}

# CloudWatchイベントルールの設定
resource "aws_cloudwatch_event_rule" "overnight_batch" {
  # イベントルール名
  name = "${var.project_name}-overnight-batch"
  # イベントルールのスケジュール式(CRON)
  schedule_expression = "cron(0 15 * * ? *)" # 毎日深夜0時に実行
  # 説明
  description = var.project_name
  # タグ
  tags = {
    Name = var.project_name
  }
}

# CloudWatchイベントターゲットの設定
resource "aws_cloudwatch_event_target" "lambda_target" {
  # ターゲットID
  target_id = "${var.project_name}-overnight-batch"
  # イベントルール
  rule = aws_cloudwatch_event_rule.overnight_batch.name
  # ターゲットとなるLambda関数のARN
  arn = aws_lambda_function.lambda_overnight_batch.arn
}

# Lambda関数にEventBridgeからの実行権限を付与
resource "aws_lambda_permission" "allow_event_bridge" {
  # 宣言ID
  statement_id = "AllowExecutionFromEventBridge"
  # Lambda関数を実行するリソースのARN
  source_arn = aws_cloudwatch_event_rule.overnight_batch.arn
  # プリンシパル
  principal = "events.amazonaws.com"
  # 許可アクション
  action = "lambda:InvokeFunction"
  # 実行するLambda関数名
  function_name = aws_lambda_function.lambda_overnight_batch.function_name
}
