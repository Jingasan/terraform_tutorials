#============================================================
# S3：ビルドしたLambda関数zipファイルをデプロイするバケットの設定
#============================================================

# Lambda関数のzipファイルをデプロイするS3バケットの設定
resource "aws_s3_bucket" "bucket_lambda" {
  # S3バケット名
  bucket = "${var.project_name}-lambda-${local.project_stage}"
  # バケットの中にオブジェクトが入っていてもTerraformに削除を許可するかどうか(true:許可)
  force_destroy = true
  # タグ
  tags = {
    Name = "${var.project_name}-lambda-${local.project_stage}"
  }
}



#============================================================
# S3：Webアプリ用バケットの設定
#============================================================

# Webアプリ用バケットの作成
resource "aws_s3_bucket" "bucket_app" {
  # S3バケット名
  bucket = "${var.project_name}-app-${local.project_stage}"
  # バケットの中にオブジェクトが入っていてもTerraformに削除を許可するかどうか(true:許可)
  force_destroy = var.s3_bucket_force_destroy
  # タグ
  tags = {
    Name = "${var.project_name}-app-${local.project_stage}"
  }
}

# バケットポリシー
resource "aws_s3_bucket_policy" "bucket_app" {
  # バケットポリシーの設定対象バケットのID
  bucket = aws_s3_bucket.bucket_app.id
  # CloudFront Distributionからのアクセスのみ許可するポリシーを追加
  policy = data.aws_iam_policy_document.bucket_app_policy.json
}
# CloudFront Distributionからのアクセスのみ許可するポリシー
data "aws_iam_policy_document" "bucket_app_policy" {
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
    resources = ["${aws_s3_bucket.bucket_app.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudfront_distribution.common.arn]
    }
  }
}

# CORSの設定
resource "aws_s3_bucket_cors_configuration" "bucket_app" {
  # CORSの設定対象バケットのID
  bucket = aws_s3_bucket.bucket_app.id
  # CORSルール
  cors_rule {
    allowed_headers = ["*"]   # 許可するリクエストヘッダー
    allowed_methods = ["GET"] # オリジン間リクエストで許可するHTTPメソッド
    allowed_origins = ["*"]   # オリジン間アクセスを許可するアクセス元
    expose_headers  = []      # ブラウザからアクセスを許可するレスポンスヘッダー
  }
}

# オブジェクトのバージョン管理の設定
resource "aws_s3_bucket_versioning" "bucket_app" {
  # バージョン管理を設定するバケットのID
  bucket = aws_s3_bucket.bucket_app.id
  # バージョン管理の設定
  versioning_configuration {
    # バージョン管理のステータス(Enabled:有効)
    status = "Enabled"
  }
}

# S3バケットオブジェクトのライフサイクルルール(オブジェクトが永遠にバージョニングされない為に必須)
resource "aws_s3_bucket_lifecycle_configuration" "bucket_app" {
  # 対象となるバケットのID
  bucket = aws_s3_bucket.bucket_app.id
  # ライフサイクルルールの設定
  rule {
    # ルール名
    id = "${var.project_name}-app-${local.project_stage}"
    # ルールのステータス(Enabled:有効)
    status = "Enabled"
    # ルール適用対象のオブジェクトをprefixで指定
    filter {
      prefix = "" # すべてのオブジェクトに適用
    }
    # オブジェクトの非最新バージョンの削除設定
    noncurrent_version_expiration {
      # 非最新バージョンの保持日数(日)：指定日数が経過したら非最新バージョンを削除する
      noncurrent_days = var.s3_lifecycle_noncurrent_version_expiration_days
      # 保持するバージョン数(個)
      newer_noncurrent_versions = var.s3_lifecycle_newer_noncurrent_versions
    }
  }
}

# Webページのアップロード
locals {
  src_dir = "s3"                                      # アップロード対象のディレクトリ
  dst_dir = "s3://${aws_s3_bucket.bucket_app.bucket}" # アップロード先
}
resource "null_resource" "fileupload" {
  # S3バケット作成完了後に実行
  depends_on = [aws_s3_bucket.bucket_app]
  # ソースコードに差分があった場合にのみ実行
  triggers = {
    code_diff = join("", [
      for file in fileset("${local.src_dir}/src", "{*}")
      : filebase64("${local.src_dir}/src/${file}")
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
