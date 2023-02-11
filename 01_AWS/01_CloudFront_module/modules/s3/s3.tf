### S3

# 引数
variable "aws_cloudfront_distribution_arn" {
}

# バケット名とタグの設定
resource "aws_s3_bucket" "main" {
  bucket = "terraform-tutorial-bucket-name"
  # タグ
  tags = {
    Name = "Terraform検証用"
  }
}

# パブリックアクセスのブロック設定
resource "aws_s3_bucket_public_access_block" "main" {
  bucket                  = aws_s3_bucket.main.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# バケットポリシー
resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  # CloudFront Distributionからのアクセスのみ許可するポリシーを追加
  policy = data.aws_iam_policy_document.s3_main_policy.json
}
# CloudFront Distributionからのアクセスのみ許可するポリシー
data "aws_iam_policy_document" "s3_main_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
	}
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.main.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [var.aws_cloudfront_distribution_arn]
    }
  }
}

# 戻り値
output "aws_s3_bucket" {
	value = aws_s3_bucket.main
}