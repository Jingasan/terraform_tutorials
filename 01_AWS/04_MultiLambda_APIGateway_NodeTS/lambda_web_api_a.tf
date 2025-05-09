#============================================================
# Lambda（仮のWebAPI用Lambda関数（LGWAN向けAPI Gatewayの初回デプロイに必要））
#============================================================

locals {
  # Lambda関数のpackage.jsonがあるディレクトリのこのファイルから見た相対パス
  lambda_web_api_a_dir_path = "lambda/web_api_a"
  # Lambda関数のデプロイ先S3バケットキー
  lambda_web_api_a_s3_key = "web_api_a/lambda.zip"
}

# Lambda関数の設定
resource "aws_lambda_function" "lambda_web_api_a" {
  # 関数のZIPファイルをS3にアップロードした後に実行
  depends_on = [null_resource.lambda_web_api_a_build_upload]
  # 関数名
  function_name = "${var.project_name}-web-api-a-${local.project_stage}"
  # 実行ランタイム（ex: nodejs, python, go, etc.）
  runtime = var.lambda_runtime
  # ハンドラの指定
  handler = "dist/index.handler"
  # 作成するLambda関数に対して許可するIAMロールの指定
  role = aws_iam_role.lambda_role.arn
  # Lambda関数のコード取得元S3バケットとパス
  s3_bucket = aws_s3_bucket.bucket_lambda.bucket
  s3_key    = local.lambda_web_api_a_s3_key
  # Lambda関数のタイムアウト時間（秒）（Lambdaの場合：最大900秒，Lambda@Edgeの場合：最大5秒）
  timeout = 900
  # 新しいLambda関数のバージョンを発行するか（false(default):しない）
  publish = false
  # 環境変数の指定
  environment {
    variables = {
      SERVICE_NAME = "${var.project_name}-${local.project_stage}" # サービス名
      REGION       = var.region                                   # リージョン
    }
  }
  # 作成するLambdaの説明文
  description = "${var.project_name} aws resource web api function ${local.project_stage}"
  # タグ
  tags = {
    Name = "${var.project_name}-web-api-a-${local.project_stage}"
  }
}

# Lambda関数のローカルビルドコマンドの設定
resource "null_resource" "lambda_web_api_a_build_upload" {
  # ビルド済みの関数zipファイルアップロード先のS3バケットが生成されたら実行
  depends_on = [aws_s3_bucket.bucket_lambda]
  # ソースコードに差分があった場合に実行
  triggers = {
    code_diff = join("", [
      for file in fileset("${local.lambda_web_api_a_dir_path}/src", "{*.mts, package*.json}")
      : filebase64("${local.lambda_web_api_a_dir_path}/src/${file}")
    ])
    package_diff = join("", [
      for file in fileset("${local.lambda_web_api_a_dir_path}", "{package*.json}")
      : filebase64("${local.lambda_web_api_a_dir_path}/${file}")
    ])
  }
  # Lambda関数依存パッケージのインストール
  provisioner "local-exec" {
    # 実行するコマンド
    command = "npm install"
    # コマンドを実行するディレクトリ
    working_dir = local.lambda_web_api_a_dir_path
  }
  # Lambda関数のビルド
  provisioner "local-exec" {
    command     = "npm run build"
    working_dir = local.lambda_web_api_a_dir_path
  }
  # Lambda関数のZIP圧縮
  provisioner "local-exec" {
    command     = "zip -r lambda.zip dist node_modules"
    working_dir = local.lambda_web_api_a_dir_path
  }
  # S3アップロード
  provisioner "local-exec" {
    command     = "aws s3 cp --profile ${var.profile} lambda.zip s3://${aws_s3_bucket.bucket_lambda.bucket}/${local.lambda_web_api_a_s3_key}"
    working_dir = local.lambda_web_api_a_dir_path
  }
}

# Lambda関数の更新
resource "null_resource" "lambda_web_api_a_update" {
  # Lambda関数作成後に実行
  depends_on = [null_resource.lambda_web_api_a_build_upload, aws_lambda_function.lambda_web_api_a]
  # ソースコードに差分があった場合にのみ実行
  triggers = {
    code_diff = join("", [
      for file in fileset("${local.lambda_web_api_a_dir_path}/src", "{*.mts}")
      : filebase64("${local.lambda_web_api_a_dir_path}/src/${file}")
    ])
    package_diff = join("", [
      for file in fileset("${local.lambda_web_api_a_dir_path}", "{package*.json}")
      : filebase64("${local.lambda_web_api_a_dir_path}/${file}")
    ])
  }
  # Lambda関数を更新
  provisioner "local-exec" {
    command     = "aws lambda update-function-code --profile ${var.profile} --function-name ${aws_lambda_function.lambda_web_api_a.function_name} --s3-bucket ${aws_s3_bucket.bucket_lambda.bucket} --s3-key ${local.lambda_web_api_a_s3_key} --publish --no-cli-pager"
    working_dir = local.lambda_web_api_a_dir_path
  }
}



#============================================================
# CloudWatch Logs
#============================================================

# CloudWatchロググループの設定
# Lambdaでは、自動で/aws/lambda/<関数名>というロググループが生成される
# ログの保存期間を設定する場合に、以下の設定が必要。
resource "aws_cloudwatch_log_group" "lambda_web_api_a" {
  # CloudWatchロググループ名
  name = "/aws/lambda/${aws_lambda_function.lambda_web_api_a.function_name}"
  # CloudWatchにログを残す期間（日）
  retention_in_days = var.lambda_cloudwatch_log_retention_in_days
  # タグ
  tags = {
    Name = aws_lambda_function.lambda_web_api_a.function_name
  }
}



#============================================================
# Lambda関数を更新するスクリプトの作成
#============================================================

# Lambda関数を更新するスクリプトの出力
resource "local_file" "deploy_lambda_web_api_a_script" {
  # 出力先
  filename = "./script/deploy_lambda_web_api_a.sh"
  # 出力ファイルのパーミッション
  file_permission = "0755"
  # 出力ファイルの内容
  content = <<DOC
#!/bin/bash
# Lambda関数を更新するスクリプト（自動生成）

# コマンドライン引数チェック
echo "> $0 $*"
if [ $# != 1 ]; then
    echo "Please set deploy target awscli profile."
    echo "Usage: $0 [AWS Profile]"
    exit 1
fi
# AWS Profile名の取得
profile=$1
echo "awscli profile: $profile"

# 本スクリプトのあるディレクトリに移動
THIS_SCRIPT_DIR=$(cd $(dirname $0); pwd)
pushd $THIS_SCRIPT_DIR > /dev/null 2>&1

# Lambda関数があるディレクトリに移動
pushd ../${local.lambda_web_api_a_dir_path} > /dev/null 2>&1

# Lambda関数をビルド
npm install
npm run build

# Lambda関数をZIP圧縮
zip -r lambda.zip dist node_modules

# Lambda関数のZIPファイルをS3にアップロード
aws s3 cp --profile ${var.profile} lambda.zip s3://${aws_s3_bucket.bucket_lambda.bucket}/${local.lambda_web_api_a_s3_key}

# Lambda関数を更新
aws lambda update-function-code --profile ${var.profile} --function-name ${aws_lambda_function.lambda_web_api_a.function_name} --s3-bucket ${aws_s3_bucket.bucket_lambda.bucket} --s3-key ${local.lambda_web_api_a_s3_key} --publish --no-cli-pager

# 元のディレクトリに戻る
popd > /dev/null 2>&1
popd > /dev/null 2>&1
DOC
}
