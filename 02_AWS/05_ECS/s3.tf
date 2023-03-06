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

# バケットポリシー
resource "aws_s3_bucket_policy" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id
  policy = data.aws_iam_policy_document.alb_log.json
}
data "aws_iam_policy_document" "alb_log" {
  statement {
    sid    = ""
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
