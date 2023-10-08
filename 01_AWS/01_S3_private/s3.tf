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
  bucket                  = aws_s3_bucket.frontend.id
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

# オブジェクトのバージョン管理の設定
resource "aws_s3_bucket_versioning" "frontend" {
  # バージョン管理を設定するバケットのID
  bucket = aws_s3_bucket.frontend.id
  # バージョン管理の設定
  versioning_configuration {
    status = "Enabled"
  }
}
