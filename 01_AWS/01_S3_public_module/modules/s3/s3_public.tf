### S3

# バケット名とタグの設定
resource "aws_s3_bucket" "main" {
  bucket = "terraform-tutorial-public-bucket-name"

  # バケットの中にオブジェクトが入っていてもTerraformに削除を許可するかどうか(true:許可)
  force_destroy = true

  # タグ
  tags = {
    Name = "Terraform検証用"
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
  # ブロックパブリックアクセスの設定がされてからバケットポリシーの設定を行う
  depends_on = [
    aws_s3_bucket_public_access_block.main,
  ]
}
# パブリックアクセスを許可するポリシー
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
locals {
  src_dir = "./webpage"                         # アップロード対象のディレクトリ
  dst_dir = "s3://${aws_s3_bucket.main.bucket}" # アップロード先
}
resource "null_resource" "fileupload" {
  # S3バケット作成完了後に実行
  triggers = {
    trigger = "${aws_s3_bucket.main.id}"
  }

  # ローカルディレクトリにあるWebページをS3バケットにアップロード
  provisioner "local-exec" {
    command = "aws s3 cp ${local.src_dir} ${local.dst_dir} --recursive"
  }
}
