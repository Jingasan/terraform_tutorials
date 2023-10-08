#============================================================
# CloudFront
#============================================================

# ディストリビューションの設定
resource "aws_cloudfront_distribution" "api" {
  # ディストリビューションの有効化
  enabled = true
  # オリジンの設定
  origin {
    domain_name = "${aws_lambda_function_url.lambda.url_id}.lambda-url.${var.region}.on.aws"
    origin_id   = "lambda"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }
  # 証明書管理
  viewer_certificate {
    # CloudFrontのデフォルトの証明書を使用(ACMで発行した証明書に切り替えることも可能)
    cloudfront_default_certificate = true
  }
  # デフォルトキャッシュビヘイビアの設定
  default_cache_behavior {
    target_origin_id       = "lambda"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = aws_cloudfront_cache_policy.CachingDisabledCookieQueryEnabled.id
  }
  # アクセス制限
  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }
  # 説明
  comment = var.project_name
  # タグ
  tags = {
    Name = var.project_name
  }
}

# カスタムキャッシュポリシー
resource "aws_cloudfront_cache_policy" "CachingDisabledCookieQueryEnabled" {
  name    = "CachingDisabledCookieQueryEnabled"
  comment = "キャッシュ無効・クッキー有効・クエリ有効"
  # キャッシュTTLの設定(秒)
  default_ttl = 1
  max_ttl     = 1
  min_ttl     = 1
  # 許可するHTTPヘッダー
  parameters_in_cache_key_and_forwarded_to_origin {
    headers_config {
      header_behavior = "whitelist"
      headers {
        items = [
          "Origin",
          "Access-Control-Request-Method",
          "Access-Control-Request-Headers",
          "Referer"
        ]
      }
    }
    # 許可するCookie
    cookies_config {
      cookie_behavior = "all"
    }
    # 許可するURLクエリ
    query_strings_config {
      query_string_behavior = "all"
    }
    # Gzip/Brotli圧縮されたオブジェクトをCloudFrontがリクエスト／キャッシュできるようにする
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}

# Cloudfront distributionのURL出力
output "cloudfront_distribution_url" {
  description = "CloudFront distribution URL"
  value       = "https://${aws_cloudfront_distribution.api.domain_name}/"
}
