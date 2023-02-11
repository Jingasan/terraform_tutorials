### CloudFront

# ディストリビューションの設定
resource "aws_cloudfront_distribution" "main" {
  # ディストリビューションの有効化
  enabled = true

  # オリジンの設定
  origin {
    origin_id   = aws_s3_bucket.main.id
    domain_name = aws_s3_bucket.main.bucket_regional_domain_name
    # OAC を設定
    origin_access_control_id = aws_cloudfront_origin_access_control.main.id
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # デフォルトキャッシュビヘイビアの設定
  default_cache_behavior {
    target_origin_id           = aws_s3_bucket.main.id
    viewer_protocol_policy     = "redirect-to-https"
    cached_methods             = ["GET", "HEAD"]
    allowed_methods            = ["GET", "HEAD"]
    cache_policy_id            = data.aws_cloudfront_cache_policy.CachingOptimized.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.CORS-S3Origin.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.SimpleCORS.id
  }

  # アクセス制限
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # 説明
  comment = "Terraform検証用"

  # タグ
  tags = {
    Name = "Terraform検証用"
  }
}

# キャッシュポリシー
data "aws_cloudfront_cache_policy" "CachingOptimized" {
  # AWSのマネージドポリシーを指定
  name = "Managed-CachingOptimized"
}

# オリジンリクエストポリシー
data "aws_cloudfront_origin_request_policy" "CORS-S3Origin" {
  # AWSのマネージドポリシーを指定
  name = "Managed-CORS-S3Origin"
}

# レスポンスヘッダーポリシー
data "aws_cloudfront_response_headers_policy" "SimpleCORS" {
  # AWSのマネージドポリシーを指定
  name = "Managed-SimpleCORS"
}

# OACの作成
resource "aws_cloudfront_origin_access_control" "main" {
  name                              = "cloudfront-origin-access-control"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
