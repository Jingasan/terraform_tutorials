#============================================================
# CloudFront
#============================================================

# ディストリビューションの設定
resource "aws_cloudfront_distribution" "api" {
  # ディストリビューションの有効化
  enabled = true
  # デフォルトルートオブジェクトの設定
  default_root_object = "index.html"
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
    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }
    min_ttl     = 60
    default_ttl = 60
    max_ttl     = 60
    compress    = true
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

# Cloudfront distributionのURL出力
output "cloudfront_distribution_url" {
  description = "CloudFront distribution URL"
  value       = "https://${aws_cloudfront_distribution.api.domain_name}/"
}
