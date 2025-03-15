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

# バックアップを許可するバケットポリシーの設定
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
