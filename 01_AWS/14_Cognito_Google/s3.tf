#============================================================
# S3
#============================================================

# バケット名とタグの設定
resource "aws_s3_bucket" "frontend" {
  # バケット名
  bucket = "${var.project_name}-${local.lower_random_hex}"
  # バケットの中にオブジェクトが入っていてもTerraformに削除を許可するかどうか(true:許可)
  force_destroy = true
  # タグ
  tags = {
    Name = var.project_name
  }
}

# パブリックアクセスのブロック設定
resource "aws_s3_bucket_public_access_block" "frontend" {
  # パブリックアクセスブロックを設定するバケット名
  bucket = aws_s3_bucket.frontend.id
  # パブリックアクセスのブロック
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 他のAWSアカウントによるバケットアクセスコントロールの設定
resource "aws_s3_account_public_access_block" "frontend" {
  block_public_acls   = false
  block_public_policy = false
}

# バケットポリシー
resource "aws_s3_bucket_policy" "main" {
  # バケットポリシーを設定するバケットのID
  bucket = aws_s3_bucket.frontend.id
  # CloudFront Distributionからのアクセスのみ許可するポリシーを追加
  policy = data.aws_iam_policy_document.s3_main_policy.json
}
# CloudFront Distributionからのアクセスのみ許可するポリシー
data "aws_iam_policy_document" "s3_main_policy" {
  statement {
    sid    = "0"
    effect = "Allow"
    # アクセス元の設定
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    # バケットに対して制御するアクションの設定
    actions = ["s3:GetObject"]
    # アクセス先の設定
    resources = ["${aws_s3_bucket.frontend.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudfront_distribution.main.arn]
    }
  }
}

# CORSの設定
resource "aws_s3_bucket_cors_configuration" "frontend" {
  # CORを設定するバケットのID
  bucket = aws_s3_bucket.frontend.id
  # CORSルール
  cors_rule {
    allowed_headers = ["*"]   # 許可するリクエストヘッダー
    allowed_methods = ["GET"] # オリジン間リクエストで許可するHTTPメソッド
    allowed_origins = ["*"]   # オリジン間アクセスを許可するアクセス元
    expose_headers  = []      # ブラウザからアクセスを許可するレスポンスヘッダー
  }
}

# オブジェクトのバージョン管理の設定
resource "aws_s3_bucket_versioning" "frontend" {
  # バージョン管理を設定するバケットのID
  bucket = aws_s3_bucket.frontend.id
  # バージョン管理の設定
  versioning_configuration {
    status = "Enabled"
  }
}

# Webページのアップロード
locals {
  src_dir = "frontend"                              # アップロード対象のディレクトリ
  dst_dir = "s3://${aws_s3_bucket.frontend.bucket}" # アップロード先
}
resource "null_resource" "fileupload" {
  # S3バケット作成完了後に実行
  depends_on = [aws_s3_bucket.frontend, local_file.frontend_cognito_config]
  # ソースコードに差分があった場合にのみ実行
  triggers = {
    code_diff = join("", [
      for file in fileset("${local.src_dir}/src", "{*}")
      : filebase64("${local.src_dir}/src/${file}") if file != "config.json"
    ])
    public_diff = join("", [
      for file in fileset("${local.src_dir}/public", "{*}")
      : filebase64("${local.src_dir}/public/${file}")
    ])
    package_diff = join("", [
      for file in fileset("${local.src_dir}", "{*}")
      : filebase64("${local.src_dir}/${file}")
    ])
  }
  # React Webアプリの依存パッケージインストール
  provisioner "local-exec" {
    command     = "npm install"
    working_dir = local.src_dir
  }
  # React Webアプリのビルド
  provisioner "local-exec" {
    command     = "npm run build"
    working_dir = local.src_dir
  }
  # ローカルディレクトリにあるWebページをS3バケットにアップロード
  provisioner "local-exec" {
    command = "aws s3 cp --profile ${var.profile} ${local.src_dir}/dist ${local.dst_dir} --recursive"
  }
}
