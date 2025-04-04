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
# 不特定多数からのアクセスを許可するバケットポリシー
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

# S3バケットオブジェクトのライフサイクルルール(オブジェクトが永遠にバージョニングされない為に必須)
resource "aws_s3_bucket_lifecycle_configuration" "frontend" {
  # 対象となるバケットのID
  bucket = aws_s3_bucket.frontend.id
  # ライフサイクルルールの設定
  rule {
    # ルール名
    id = "${var.project_name}-bucket-frontend-${local.lower_random_hex}"
    # ルールのステータス(Enabled:有効)
    status = "Enabled"
    # ルール適用対象のオブジェクトをprefixで指定
    filter {
      prefix = "" # すべてのオブジェクトに適用
    }
    # オブジェクトの非最新バージョンの削除設定
    noncurrent_version_expiration {
      # 非最新バージョンの保持日数(日)：指定日数が経過したら非最新バージョンを削除する
      noncurrent_days = var.s3_bucket_lifecycle_noncurrent_version_expiration_days
      # 保持するバージョン数(個)
      newer_noncurrent_versions = var.s3_bucket_lifecycle_newer_noncurrent_versions
    }
  }
}

# Webページのアップロード
locals {
  src_dir = "./webpage"                             # アップロード対象のディレクトリ
  dst_dir = "s3://${aws_s3_bucket.frontend.bucket}" # アップロード先
}
resource "null_resource" "fileupload" {
  # S3バケット作成完了後に実行
  triggers = {
    trigger = "${aws_s3_bucket.frontend.id}"
  }
  # ローカルディレクトリにあるWebページをS3バケットにアップロード
  provisioner "local-exec" {
    command = "aws s3 cp --profile ${var.profile} ${local.src_dir} ${local.dst_dir} --recursive"
  }
}

# WebサイトURLのターミナル出力
output "url" {
  value = "https://${aws_s3_bucket.frontend.bucket_domain_name}/index.html"
}
