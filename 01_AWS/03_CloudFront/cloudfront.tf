#============================================================
# CloudFront
#============================================================

# ディストリビューションの設定
resource "aws_cloudfront_distribution" "main" {
  # ディストリビューションの有効化
  enabled = true

  # デフォルトルートオブジェクトの設定
  default_root_object = "index.html"

  # オリジンの設定
  origin {
    origin_id   = aws_s3_bucket.main.id
    domain_name = aws_s3_bucket.main.bucket_regional_domain_name
    # OAC を設定
    origin_access_control_id = aws_cloudfront_origin_access_control.main.id
  }

  # 証明書管理
  viewer_certificate {
    # CloudFrontのデフォルトの証明書を使用(ACMで発行した証明書に切り替えることも可能)
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
      locations        = []
    }
  }

  # 説明
  comment = var.tag_name

  # タグ
  tags = {
    Name = var.tag_name
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

# Cloudfront distributionのURL出力
output "cloudfront_distribution_url" {
  description = "CloudFront distribution URL"
  value       = "https://${aws_cloudfront_distribution.main.domain_name}"
}