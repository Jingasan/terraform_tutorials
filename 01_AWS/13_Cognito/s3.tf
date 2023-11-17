#============================================================
# S3 - 公開バケット
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
  # パブリックアクセスブロックを設定するバケット
  bucket = aws_s3_bucket.frontend.id
  # バケットポリシーに基づいてアクセスを許可するため、ブロックを無効化
  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

# 他のAWSアカウントによるバケットアクセスコントロールの設定
resource "aws_s3_account_public_access_block" "frontend" {
  # 拒否
  block_public_acls   = false
  block_public_policy = false
}

# バケットポリシー
resource "aws_s3_bucket_policy" "frontend" {
  # バケットポリシーを設定するバケットのID
  bucket = aws_s3_bucket.frontend.id
  # 不特定多数からのアクセスを許可するバケットポリシーを追加
  policy = data.aws_iam_policy_document.s3_main_policy.json
  # ブロックパブリックアクセスの設定がされてからバケットポリシーの設定を行う
  depends_on = [
    aws_s3_bucket_public_access_block.frontend,
  ]
}
# CloudFront Distributionからのアクセスのみ許可するポリシー
data "aws_iam_policy_document" "s3_main_policy" {
  statement {
    sid    = "0"
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
      "${aws_s3_bucket.frontend.arn}",  # S3バケットへのアクセス。
      "${aws_s3_bucket.frontend.arn}/*" # S3バケット配下へのアクセス。
    ]
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
    command = "aws s3 cp ${local.src_dir}/dist ${local.dst_dir} --recursive"
  }
}

# 静的Webサイトホスティング
resource "aws_s3_bucket_website_configuration" "example" {
  # 対象バケットのID
  bucket = aws_s3_bucket.frontend.id
  # インデックスドキュメント：Webサイトのデフォルトページ
  index_document {
    suffix = "index.html"
  }
  # エラードキュメント：エラー発生時のリダイレクト先
  error_document {
    key = "index.html"
  }
}

# WebサイトURLのターミナル出力
output "url" {
  description = "Web Page URL"
  value       = "http://${aws_s3_bucket_website_configuration.example.website_endpoint}"
}
