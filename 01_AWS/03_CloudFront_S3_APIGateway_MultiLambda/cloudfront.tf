#============================================================
# CloudFront
#============================================================

# ディストリビューションの設定
resource "aws_cloudfront_distribution" "common" {
  # ディストリビューションの有効化
  enabled = true
  # デフォルトルートオブジェクトの設定
  default_root_object = "index.html"
  # 価格クラス(PriceClass_All/PriceClass_200/PriceClass_100)
  # PriceClass_Allは、すべてのリージョンを使用する。
  # PriceClass_200は、北米、欧州、アフリカ、日本を含むアジア太平洋地域のリージョンを使用する。
  # PriceClass_100は、北米、欧州のリージョンを使用する。(日本が含まれない為、利用非推奨)
  price_class = var.cloudfront_price_class
  # 証明書管理
  viewer_certificate {
    # CloudFrontのデフォルトの証明書を使用するか（true:使用する/false:使用せず、ACMなどで発行した証明書を使用する）
    cloudfront_default_certificate = true
  }
  lifecycle {
    # サーバー証明書はCloudFront構築後に手動で割り当てる為、
    # サーバー証明書やドメイン関連の設定項目はterraformの管理対象外にする。
    ignore_changes = [
      viewer_certificate,
      aliases
    ]
  }
  # S3 Webアプリ用バケットのオリジン設定
  origin {
    # オリジンID
    origin_id = "s3-bucket-app"
    # S3 frontenバケットのドメイン名
    domain_name = aws_s3_bucket.bucket_app.bucket_regional_domain_name
    # OAC を設定
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_bucket.id
  }
  # API Gatewayのオリジン設定
  origin {
    # オリジンID
    origin_id = "api-gateway"
    # API Gatewayのドメイン名
    domain_name = "${aws_api_gateway_rest_api.api.id}.execute-api.${var.region}.amazonaws.com"
    # オリジンのパス
    origin_path = "/${aws_api_gateway_stage.stage.stage_name}"
    # 許可するプロトコル
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }
  # デフォルトキャッシュビヘイビアの設定（S3 Webアプリバケット用のキャッシュビヘイビアの設定）
  default_cache_behavior {
    # オリジンID
    target_origin_id = "s3-bucket-app"
    # HTTPはHTTPSにリダイレクトする
    viewer_protocol_policy = "redirect-to-https"
    # 許可するHTTPメソッド
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    # キャッシュするHTTPメソッド
    cached_methods = ["GET", "HEAD", "OPTIONS"]
    # キャッシュポリシー
    cache_policy_id = aws_cloudfront_cache_policy.CachingOptimized.id
    # オリジンリクエストポリシー
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.CORS_S3Origin.id
    # レスポンスヘッダーポリシー
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.SimpleCORS.id
  }
  # API Gateway用のキャッシュビヘイビアの設定
  ordered_cache_behavior {
    # オリジンID
    target_origin_id = "api-gateway"
    # パスパターン（API GatewayへのURLのパスを定義する）
    path_pattern = "/api/*"
    # HTTPはHTTPSにリダイレクトする
    viewer_protocol_policy = "redirect-to-https"
    # 許可するHTTPメソッド
    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    # キャッシュするHTTPメソッド
    cached_methods = ["GET", "HEAD"]
    # キャッシュポリシー
    cache_policy_id = aws_cloudfront_cache_policy.CachingDisabledCookieQueryEnabled.id
  }
  # アクセス制限
  restrictions {
    # 国・地域によるアクセス制限
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["JP", "US"] # 日本とアメリカのみアクセス可能
    }
  }
  # 説明
  comment = "${var.project_name}-cloudfront-${local.project_stage}"
  # タグ
  tags = {
    Name = "${var.project_name}-cloudfront-${local.project_stage}"
  }
}

# カスタムキャッシュポリシー
resource "aws_cloudfront_cache_policy" "CachingOptimized" {
  # キャッシュポリシー名
  name = "${var.project_name}-caching-optimized-${local.project_stage}"
  # 説明
  comment = "キャッシュ有効・ヘッダー有効・クッキー有効・クエリ有効"
  # キャッシュTTLの設定（秒）
  default_ttl = 86400
  max_ttl     = 31536000
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
resource "aws_cloudfront_cache_policy" "CachingDisabledCookieQueryEnabled" {
  # キャッシュポリシー名
  name = "${var.project_name}-caching-disabled-cookie-query-enabled-${local.project_stage}"
  # 説明
  comment = "キャッシュ無効・クッキー有効・クエリ有効"
  # キャッシュTTLの設定（秒）
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

# オリジンリクエストポリシー
data "aws_cloudfront_origin_request_policy" "CORS_S3Origin" {
  # AWSのマネージドポリシーを指定
  name = "Managed-CORS-S3Origin"
}

# レスポンスヘッダーポリシー
data "aws_cloudfront_response_headers_policy" "SimpleCORS" {
  # AWSのマネージドポリシーを指定
  name = "Managed-SimpleCORS"
}

# OACの作成
resource "aws_cloudfront_origin_access_control" "s3_bucket" {
  # OACの名前
  name = "${var.project_name}-cloudfront-origin-access-control-${local.project_stage}"
  # オリジンの種類
  origin_access_control_origin_type = "s3"
  # CloudFrontがリクエストを署名するかどうか（always:常に署名する/never:署名しない/no-override:オリジン設定に従う）
  signing_behavior = "always"
  # 署名方法
  signing_protocol = "sigv4"
}

# CloudFront URLの表示
output "cloudfront_web_page_url" {
  value       = "https://${aws_cloudfront_distribution.common.domain_name}/index.html"
  description = "Web Page URL"
}
output "cloudfront_web_api_a_url" {
  value       = "https://${aws_cloudfront_distribution.common.domain_name}/api/a/test"
  description = "Web API A URL"
}
output "cloudfront_web_api_b_url" {
  value       = "https://${aws_cloudfront_distribution.common.domain_name}/api/b/test"
  description = "Web API B URL"
}
