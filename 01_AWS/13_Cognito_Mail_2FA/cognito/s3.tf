#============================================================
# S3：ビルドしたLambda関数zipファイルをデプロイするバケットの設定
#============================================================

# Lambda関数のzipファイルをデプロイするS3バケットの設定
resource "aws_s3_bucket" "bucket_lambda" {
  # S3バケット名
  bucket = "${var.project_name}-lambda-${local.lower_random_hex}"
  # バケットの中にオブジェクトが入っていてもTerraformに削除を許可するかどうか(true:許可)
  force_destroy = true
  # タグ
  tags = {
    Name = var.project_name
  }
}


#============================================================
# S3：Cognitoのユーザー情報をバックアップするバケットの設定
#============================================================

# Cognitoのユーザー情報をバックアップするS3バケットの設定
resource "aws_s3_bucket" "bucket_cognito_backup" {
  # S3バケット名
  bucket = "${var.project_name}-cognito-backup-${local.lower_random_hex}"
  # バケットの中にオブジェクトが入っていてもTerraformに削除を許可するかどうか(true:許可)
  force_destroy = true
  # タグ
  tags = {
    Name = var.project_name
  }
}

# バックアップを許可するバケットポリシーの設定(AWS Backupからのアクセスを許可)
resource "aws_s3_bucket_policy" "backup_policy" {
  # 割り当て先のバケット
  bucket = aws_s3_bucket.bucket_cognito_backup.id
  # バケットポリシー
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "${aws_iam_role.backup_role.arn}"
      }
      Action = [
        "s3:*",
      ]
      Resource = [
        "${aws_s3_bucket.bucket_cognito_backup.arn}",
        "${aws_s3_bucket.bucket_cognito_backup.arn}/*"
      ]
    }]
  })
}

# オブジェクトのバージョン管理の設定(AWS Backupの為に必須)
resource "aws_s3_bucket_versioning" "bucket_cognito_backup" {
  # バージョン管理を設定するバケットのID
  bucket = aws_s3_bucket.bucket_cognito_backup.id
  # バージョン管理の設定
  versioning_configuration {
    # バージョン管理のステータス(Enabled:有効)
    status = "Enabled"
  }
}

# S3バケットオブジェクトのライフサイクルルール(オブジェクトが永遠にバージョニングされない為に必須)
resource "aws_s3_bucket_lifecycle_configuration" "bucket_cognito_backup" {
  # 対象となるバケットのID
  bucket = aws_s3_bucket.bucket_cognito_backup.id
  # ライフサイクルルールの設定
  rule {
    # ルール名
    id = "${var.project_name}-bucket-cognito-backup-${local.lower_random_hex}"
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
