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
# S3：ログアーカイブバケットの設定
#============================================================

# Lambda関数のCloudWatchログのアーカイブ用S3バケットの設定
resource "aws_s3_bucket" "bucket_lambda_cloudwatch_log" {
  # S3バケット名
  bucket = "${var.project_name}-lambda-cloudwatch-log"
  # バケットの中にオブジェクトが入っていてもTerraformに削除を許可するかどうか(true:許可)
  force_destroy = true
  # タグ
  tags = {
    Name = var.project_name
  }
}

# S3バケットオブジェクトのライフサイクルルール（オブジェクトが永遠にバージョニングされない為に必須）
resource "aws_s3_bucket_lifecycle_configuration" "bucket_lambda_cloudwatch_log" {
  depends_on = [aws_s3_bucket.bucket_lambda_cloudwatch_log, aws_s3_bucket_versioning.bucket_lambda_cloudwatch_log]
  # 対象となるバケットのID
  bucket = aws_s3_bucket.bucket_lambda_cloudwatch_log.id
  # ライフサイクルルールの設定
  rule {
    # ルール名
    id = "${var.project_name}-lambda-cloudwatch-log"
    # ルールのステータス（Enabled:有効）
    status = "Enabled"
    # ルール適用対象のオブジェクトをprefixで指定
    filter {
      prefix = "" # すべてのオブジェクトに適用
    }
    # 移行ルール
    transition {
      # 移行先のストレージクラス
      storage_class = "DEEP_ARCHIVE"
      # ストレージクラス移行までの日数（日）：1以上の値を指定。指定日数が経過したらオブジェクトのクラスが移行する。
      days = var.s3_cloudwatch_log_lifecycle_transition_days
    }
    # オブジェクトの有効期限設定
    expiration {
      # オブジェクトの保持日数（日）：1以上の値を指定。指定日数が経過したらオブジェクトが削除される。
      days = var.s3_cloudwatch_log_lifecycle_expiration_days
    }
  }
}
