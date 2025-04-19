#==============================
# ALBログ保存先S3バケット
#==============================

# S3バケットの作成
resource "aws_s3_bucket" "alb_log" {
  # バケット名
  bucket = "linkode-terraform-alb-log"
  # バケットの中にオブジェクトが入っていてもTerraformに削除を許可するかどうか(true:許可)
  force_destroy = true
  # タグ
  tags = {
    Name = "Terraform検証用"
  }
}

# パブリックアクセスのブロック設定
resource "aws_s3_bucket_public_access_block" "alb_log" {
  bucket                  = aws_s3_bucket.alb_log.id
  block_public_acls       = false
  block_public_policy     = false # バケットポリシーに基づいてアクセスを許可するため、ブロックを無効化
  ignore_public_acls      = false
  restrict_public_buckets = false # バケットポリシーに基づいてアクセスを許可するため、ブロックを無効化
}

# 他のAWSアカウントによるバケットアクセスコントロールの設定
resource "aws_s3_account_public_access_block" "alb_log" {
  block_public_acls   = false
  block_public_policy = false
}

# バケットポリシー
resource "aws_s3_bucket_policy" "alb_log" {
  # バケット名
  bucket = aws_s3_bucket.alb_log.id
  # バケットポリシー
  policy = data.aws_iam_policy_document.alb_log.json
  # ブロックパブリックアクセスの設定がされてからバケットポリシーの設定を行う
  depends_on = [
    aws_s3_bucket_public_access_block.alb_log,
  ]
}
data "aws_iam_policy_document" "alb_log" {
  statement {
    sid    = "0"
    effect = "Allow"
    # アクセス元の設定
    principals {
      type        = "*"
      identifiers = ["*"] # 誰でもアクセスを許可
    }
    # バケットに対して制御するアクションの設定
    actions = ["s3:PutObject"]
    # アクセス先の設定
    resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]
  }
}

# S3バケットファイルのライフサイクルルール
resource "aws_s3_bucket_lifecycle_configuration" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id
  rule {
    status = "Enabled"
    id     = "s3-alb-log-lifecycle"
    expiration {
      days = 180 # 180日経過したファイルを自動的に削除する
    }
  }
}
