#============================================================
# Lambda
#============================================================

# Lambda関数の設定
resource "aws_lambda_function" "lambda_temp_pass_notify_scheduler" {
  # 関数のZIPファイルをS3にアップロードした後に実行
  depends_on = [null_resource.build_upload_lambda_temp_pass_notify_scheduler]
  # 関数名
  function_name = "${var.project_name}-temp-pass-notify-scheduler-${local.project_stage}"
  # 実行環境の指定(ex: nodejs, python, go, etc.)
  runtime = var.lambda_runtime
  # ハンドラの指定
  handler = "dist/index.handler"
  # 作成するLambda関数に対して許可するIAMロールの指定
  role = aws_iam_role.lambda_role.arn
  # Lambda関数のコード取得元S3バケットとパス
  s3_bucket = aws_s3_bucket.bucket_lambda.bucket
  s3_key    = "temp-pass-notify-scheduler/lambda.zip"
  # Lambda関数のタイムアウト時間
  timeout = var.lambda_timeout
  # 環境変数の指定
  environment {
    variables = {
      SERVICE_NAME = var.project_name
      REGION       = var.region
      SECRET_NAME  = aws_secretsmanager_secret.secretsmanager.name
    }
  }
  # 作成するLambdaの説明文
  description = var.project_name
  # タグ
  tags = {
    ProjectName        = var.project_name
    ProjectStage       = local.project_stage
    ProjectDescription = var.project_description_tag
    ResourceCreatedBy  = "terraform"
  }
}

# Lambda関数のビルドとS3アップロード
resource "null_resource" "build_upload_lambda_temp_pass_notify_scheduler" {
  # ビルド済み関数ZIPのアップロード先S3バケットが生成されたら実行
  depends_on = [aws_s3_bucket.bucket_lambda]
  # ソースコードに差分があった場合に実行
  triggers = {
    code_diff = join("", [
      for file in fileset("lambda/temp_pass_notify_scheduler/src", "{*.mts}")
      : filebase64("lambda/temp_pass_notify_scheduler/src/${file}")
    ])
    package_diff = join("", [
      for file in fileset("lambda/temp_pass_notify_scheduler", "{package*.json}")
      : filebase64("lambda/temp_pass_notify_scheduler/${file}")
    ])
  }
  # Lambda関数依存パッケージのインストール
  provisioner "local-exec" {
    # 実行するコマンド
    command = "npm install"
    # コマンドを実行するディレクトリ
    working_dir = "lambda/temp_pass_notify_scheduler"
  }
  # Lambda関数のビルド
  provisioner "local-exec" {
    command     = "npm run build"
    working_dir = "lambda/temp_pass_notify_scheduler"
  }
  # Lambda関数のZIP圧縮
  provisioner "local-exec" {
    command     = "zip -r lambda.zip dist node_modules"
    working_dir = "lambda/temp_pass_notify_scheduler"
  }
  # S3アップロード
  provisioner "local-exec" {
    command     = "aws s3 cp --profile ${var.profile} lambda.zip s3://${aws_s3_bucket.bucket_lambda.bucket}/temp-pass-notify-scheduler/lambda.zip"
    working_dir = "lambda/temp_pass_notify_scheduler"
  }
}

# Lambda関数の更新
resource "null_resource" "update_lambda_temp_pass_notify_scheduler" {
  # Lambda関数作成後に実行
  depends_on = [null_resource.build_upload_lambda_temp_pass_notify_scheduler, aws_lambda_function.lambda_temp_pass_notify_scheduler]
  # ソースコードに差分があった場合にのみ実行
  triggers = {
    code_diff = join("", [
      for file in fileset("lambda/temp_pass_notify_scheduler/src", "{*.mts}")
      : filebase64("lambda/temp_pass_notify_scheduler/src/${file}")
    ])
    package_diff = join("", [
      for file in fileset("lambda/temp_pass_notify_scheduler", "{package*.json}")
      : filebase64("lambda/temp_pass_notify_scheduler/${file}")
    ])
  }
  # Lambda関数を更新
  provisioner "local-exec" {
    command     = "aws lambda update-function-code --profile ${var.profile} --function-name ${aws_lambda_function.lambda_temp_pass_notify_scheduler.function_name} --s3-bucket ${aws_s3_bucket.bucket_lambda.bucket} --s3-key temp-pass-notify-scheduler/lambda.zip --publish --no-cli-pager"
    working_dir = "lambda/temp_pass_notify_scheduler"
  }
}

# CloudWatchロググループの設定
resource "aws_cloudwatch_log_group" "lambda_temp_pass_notify_scheduler" {
  # CloudWatchロググループ名
  name = "/aws/lambda/${aws_lambda_function.lambda_temp_pass_notify_scheduler.function_name}"
  # ログを残す期間(日)の指定
  retention_in_days = var.lambda_cloudwatch_log_retention_in_days
  # タグ
  tags = {
    ProjectName        = var.project_name
    ProjectStage       = local.project_stage
    ProjectDescription = var.project_description_tag
    ResourceCreatedBy  = "terraform"
  }
}

# CloudWatchイベントルールの設定
resource "aws_cloudwatch_event_rule" "lambda_temp_pass_notify_scheduler" {
  # イベントルール名
  name = "${var.project_name}-temp-pass-notify-scheduler-${local.project_stage}"
  # イベントルールのスケジュール式(CRON)
  schedule_expression = "cron(0 15 * * ? *)" # 毎日深夜0時に実行
  # 説明
  description = var.project_name
  # タグ
  tags = {
    ProjectName        = var.project_name
    ProjectStage       = local.project_stage
    ProjectDescription = var.project_description_tag
    ResourceCreatedBy  = "terraform"
  }
}

# CloudWatchイベントターゲットの設定
resource "aws_cloudwatch_event_target" "lambda_temp_pass_notify_scheduler" {
  # ターゲットID
  target_id = "${var.project_name}-temp-pass-notify-scheduler-${local.project_stage}"
  # イベントルール
  rule = aws_cloudwatch_event_rule.lambda_temp_pass_notify_scheduler.name
  # ターゲットとなるLambda関数のARN
  arn = aws_lambda_function.lambda_temp_pass_notify_scheduler.arn
}

# Lambda関数にEventBridgeからの実行権限を付与
resource "aws_lambda_permission" "lambda_temp_pass_notify_scheduler" {
  # 宣言ID
  statement_id = "AllowExecutionFromEventBridge"
  # Lambda関数を実行するリソースのARN
  source_arn = aws_cloudwatch_event_rule.lambda_temp_pass_notify_scheduler.arn
  # プリンシパル
  principal = "events.amazonaws.com"
  # 許可アクション
  action = "lambda:InvokeFunction"
  # 実行するLambda関数名
  function_name = aws_lambda_function.lambda_temp_pass_notify_scheduler.function_name
}
