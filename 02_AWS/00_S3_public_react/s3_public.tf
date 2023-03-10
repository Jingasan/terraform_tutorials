### S3

# バケット名とタグの設定
resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name

  # バケットの中にオブジェクトが入っていてもTerraformに削除を許可するかどうか(true:許可)
  force_destroy = true

  # タグ
  tags = {
    Name      = var.tag_name
    UpdatedAt = timestamp()
  }
}

# パブリックアクセスのブロック設定
resource "aws_s3_bucket_public_access_block" "main" {
  bucket                  = aws_s3_bucket.main.id
  block_public_acls       = true
  block_public_policy     = false # バケットポリシーに基づいてアクセスを許可するため、ブロックを無効化
  ignore_public_acls      = true
  restrict_public_buckets = false # バケットポリシーに基づいてアクセスを許可するため、ブロックを無効化
}

# 他のAWSアカウントによるバケットアクセスコントロールの設定
resource "aws_s3_account_public_access_block" "main" {
  block_public_acls   = false
  block_public_policy = false
}

# バケットポリシー
resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  # CloudFront Distributionからのアクセスのみ許可するポリシーを追加
  policy = data.aws_iam_policy_document.s3_main_policy.json
}
# パブリックアクセスを許可するポリシー
data "aws_iam_policy_document" "s3_main_policy" {
  statement {
    sid    = ""
    effect = "Allow"
    # アクセス元の設定
    principals {
      type        = "*"
      identifiers = ["*"] # 誰でもアクセスを許可
    }
    # バケットに対して制御するアクションの設定
    actions = [
      "s3:GetObject" # オブジェクトの読み取りアクション
    ]
    # アクセス先の設定
    resources = [
      "${aws_s3_bucket.main.arn}",  # S3バケットへのアクセス。
      "${aws_s3_bucket.main.arn}/*" # S3バケット配下へのアクセス。
    ]
  }
}

# CORSの設定
resource "aws_s3_bucket_cors_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  # CORSルール
  cors_rule {
    allowed_headers = ["*"]   # 許可するリクエストヘッダー
    allowed_methods = ["GET"] # オリジン間リクエストで許可するHTTPメソッド
    allowed_origins = ["*"]   # オリジン間アクセスを許可するアクセス元
    expose_headers  = []      # ブラウザからアクセスを許可するレスポンスヘッダー
  }
}

# オブジェクトのバージョン管理の設定
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ローカルで実行するコマンドの設定
resource "null_resource" "fileupload" {
  # S3バケットのUpdatedタグ更新後に実行
  triggers = {
    trigger = "${aws_s3_bucket.main.tags.UpdatedAt}"
  }
  # React Webアプリの依存パッケージインストール
  provisioner "local-exec" {
    command     = "npm install"
    working_dir = var.src_dir
  }
  # React Webアプリのビルド
  provisioner "local-exec" {
    command     = "npm run build"
    working_dir = var.src_dir
  }
  # React WebアプリをS3バケットにアップロード
  provisioner "local-exec" {
    command = "aws s3 cp ${var.upload_dir} s3://${aws_s3_bucket.main.bucket}/${var.dist_s3dir} --recursive"
  }
}

# WebアプリトップページURLのコンソール出力
output "webapp_toppage_url" {
  description = "S3"
  value       = "https://${aws_s3_bucket.main.bucket_regional_domain_name}/${var.toppage_s3key}"
}
