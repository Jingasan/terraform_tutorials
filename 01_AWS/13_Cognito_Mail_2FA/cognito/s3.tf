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
