#============================================================
# CloudFront
#============================================================

# ディストリビューションの設定
resource "aws_cloudfront_distribution" "main" {
  # ディストリビューションの有効化
  enabled = true
  # デフォルトルートオブジェクトの設定
  default_root_object = "index.html"
  # 価格クラス (PriceClass_All/PriceClass_200/PriceClass_100)
  # https://docs.aws.amazon.com/ja_jp/AmazonCloudFront/latest/DeveloperGuide/PriceClass.html
  price_class = var.cloudfront_price_class
  # オリジングループの作成
  origin_group {
    origin_id = "group"
    failover_criteria {
      status_codes = [403, 404, 500, 502]
    }
    # S3とLambdaへのアクセス振り分け用のオリジンIDを作成
    member {
      origin_id = "S3"
    }
    member {
      origin_id = "Lambda"
    }
  }
  # オリジンの設定(S3)
  origin {
    # オリジンID
    origin_id = "S3"
    # S3サービスのドメイン名
    domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
    # OAC を設定
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
  }
  # オリジンの設定(Lambda)
  origin {
    # オリジンID
    origin_id = "Lambda"
    # Lambdaサービスのドメイン名
    domain_name = "${aws_lambda_function_url.lambda.url_id}.lambda-url.${var.region}.on.aws"
    # OAC を設定
    origin_access_control_id = aws_cloudfront_origin_access_control.lambda.id
    # 許可するプロトコル
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
    # オリジンID
    target_origin_id = "S3"
    # HTTPはHTTPSにリダイレクトする
    viewer_protocol_policy = "redirect-to-https"
    # 許可するHTTPメソッド
    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    # キャッシュするHTTPメソッド
    cached_methods = ["GET", "HEAD"]
    # キャッシュポリシー
    cache_policy_id = data.aws_cloudfront_cache_policy.CachingOptimized.id
    # オリジンリクエストポリシー
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.CORS_S3Origin.id
    # レスポンスヘッダーポリシー
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.SimpleCORS.id
  }
  # デフォルトキャッシュビヘイビアの設定
  ordered_cache_behavior {
    # オリジンID
    target_origin_id = "Lambda"
    # リバースプロキシ先のURL
    path_pattern = "/api/*"
    # HTTPはHTTPSにリダイレクトする
    viewer_protocol_policy = "redirect-to-https"
    # 許可するHTTPメソッド
    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    # キャッシュするHTTPメソッド
    cached_methods = ["GET", "HEAD"]
    # キャッシュポリシー
    cache_policy_id = data.aws_cloudfront_cache_policy.CachingDisabled.id
    # オリジンリクエストポリシー
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.AllViewerExceptHostHeader.id
    # レスポンスヘッダーポリシー
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.CORSWithPreflightAndSecurityHeadersPolicy.id
  }
  # アクセス制限
  restrictions {
    # 国・地域によるアクセス制限
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

# S3用のキャッシュポリシー
data "aws_cloudfront_cache_policy" "CachingOptimized" {
  # キャッシュポリシー名
  #［AWSマネージドポリシーの一覧（詳細はAWSコンソールからCloudFrontのポリシーを参照）］
  # Managed-CachingDisabled: キャッシュをせず、すべてのリクエストをオリジンに転送する動的なコンテンツの配信（API Gatewayオリジンなど）に最適なポリシー。
  # Managed-CachingOptimized: 標準的なキャッシュ有効化 + Gzip/Brotli圧縮サポートの静的ファイル配信（S3オリジンなど）に最適なポリシー。
  # Managed-CachingOptimizedForUncompressedObjects: 標準的なキャッシュ有効化 + Gzip/Brotli圧縮のない非圧縮の静的ファイル配信（S3オリジンなど）に最適なポリシー。
  # UseOriginCacheControlHeaders: オリジンからのCache-Controlヘッダーをそのまま使用し、クエリはキャッシュキーに含めないポリシー。オリジン（例：API Gateway）で明示的にキャッシュを制御したい場合に利用する。
  # UseOriginCacheControlHeaders-QueryStrings: オリジンからのCache-Controlヘッダーをそのまま使用し、クエリもキャッシュキーに含めるポリシー。同じパスでもクエリが違えば別キャッシュとみなし、クエリ毎に異なるレスポンスを返すオリジンで利用する。
  # Managed-Elemental-MediaPackage: AWS Elemental MediaPackage 用に設計されたポリシー。
  name = "Managed-CachingOptimized"
}

# API Gateway用のキャッシュポリシー
data "aws_cloudfront_cache_policy" "CachingDisabled" {
  # キャッシュポリシー名
  #［AWSマネージドポリシーの一覧（詳細はAWSコンソールからCloudFrontのポリシーを参照）］
  # Managed-CachingDisabled: キャッシュをせず、すべてのリクエストをオリジンに転送する動的なコンテンツの配信（API Gatewayオリジンなど）に最適なポリシー。
  # Managed-CachingOptimized: 標準的なキャッシュ有効化 + Gzip/Brotli圧縮サポートの静的ファイル配信（S3オリジンなど）に最適なポリシー。
  # Managed-CachingOptimizedForUncompressedObjects: 標準的なキャッシュ有効化 + Gzip/Brotli圧縮のない非圧縮の静的ファイル配信（S3オリジンなど）に最適なポリシー。
  # UseOriginCacheControlHeaders: オリジンからのCache-Controlヘッダーをそのまま使用し、クエリはキャッシュキーに含めないポリシー。オリジン（例：API Gateway）で明示的にキャッシュを制御したい場合に利用する。
  # UseOriginCacheControlHeaders-QueryStrings: オリジンからのCache-Controlヘッダーをそのまま使用し、クエリもキャッシュキーに含めるポリシー。同じパスでもクエリが違えば別キャッシュとみなし、クエリ毎に異なるレスポンスを返すオリジンで利用する。
  # Managed-Elemental-MediaPackage: AWS Elemental MediaPackage 用に設計されたポリシー。
  name = "Managed-CachingDisabled"
}

# S3用のオリジンリクエストポリシー（CORS対応する場合に必要）
data "aws_cloudfront_origin_request_policy" "CORS_S3Origin" {
  # オリジンリクエストポリシー名
  #［AWSマネージドポリシーの一覧（詳細はAWSコンソールからCloudFrontのポリシーを参照）］
  # Managed-AllViewer: Viewer（クライアント）からのすべての情報（Cookie, クエリ文字列, ヘッダー）をオリジンに転送する。Hostヘッダーも含める。S3以外のオリジンで利用可。
  # Managed-AllViewerExceptHostHeader: Viewer（クライアント）からのすべての情報（Cookie, クエリ文字列, ヘッダー）をオリジンに転送する。Hostヘッダーは含めない。S3以外のオリジンで利用可。
  # Managed-AllViewerAndCloudFrontHeaders-2022-06:  Viewer（クライアント）からのすべての情報（Cookie, クエリ文字列, ヘッダー） + CloudFront独自のヘッダーをオリジンに渡す。
  # Managed-CORS-S3Origin: S3をオリジンとしたCORS対応構成用。S3との互換性を維持しつつ、Originヘッダー, すべてのクエリ文字列のみをS3オリジンに渡す。Cookieは渡さない。
  # Managed-CORS-CustomOrigin: カスタムオリジン（API Gateway, ALB, EC2など）とのCORS対応構成用。Originヘッダー, すべてのクエリ文字列, すべてのCookieをオリジンに渡す。
  # Managed-UserAgentRefererHeaders: User-Agent, Refererヘッダーのみをオリジンに転送する。S3以外のオリジンで利用可。
  # Managed-Elemental-MediaTailor-PersonalizedManifests: AWS Elemental MediaTailorで使用されるオリジン向けのポリシー。
  name = "Managed-CORS-S3Origin"
}

# API Gateway用のオリジンリクエストポリシー
data "aws_cloudfront_origin_request_policy" "AllViewerExceptHostHeader" {
  # オリジンリクエストポリシー名
  #［AWSマネージドポリシーの一覧（詳細はAWSコンソールからCloudFrontのポリシーを参照）］
  # Managed-AllViewer: Viewer（クライアント）からのすべての情報（Cookie, クエリ文字列, ヘッダー）をオリジンに転送する。Hostヘッダーも含める。S3以外のオリジンで利用可。
  # Managed-AllViewerExceptHostHeader: Viewer（クライアント）からのすべての情報（Cookie, クエリ文字列, ヘッダー）をオリジンに転送する。Hostヘッダーは含めない。S3以外のオリジンで利用可。
  # Managed-AllViewerAndCloudFrontHeaders-2022-06:  Viewer（クライアント）からのすべての情報（Cookie, クエリ文字列, ヘッダー） + CloudFront独自のヘッダーをオリジンに渡す。
  # Managed-CORS-S3Origin: S3をオリジンとしたCORS対応構成用。S3との互換性を維持しつつ、Originヘッダー, すべてのクエリ文字列のみをS3オリジンに渡す。Cookieは渡さない。
  # Managed-CORS-CustomOrigin: カスタムオリジン（API Gateway, ALB, EC2など）とのCORS対応構成用。Originヘッダー, すべてのクエリ文字列, すべてのCookieをオリジンに渡す。
  # Managed-UserAgentRefererHeaders: User-Agent, Refererヘッダーのみの最小限の情報をオリジンに転送する。S3以外のオリジンで利用可。
  # Managed-Elemental-MediaTailor-PersonalizedManifests: AWS Elemental MediaTailorで使用されるオリジン向けのポリシー。
  name = "Managed-AllViewerExceptHostHeader"
}

# S3用のレスポンスヘッダーポリシー（CORS対応する場合に必要）
data "aws_cloudfront_response_headers_policy" "SimpleCORS" {
  # レスポンスヘッダーポリシー名
  #［AWSマネージドポリシーの一覧（詳細はAWSコンソールからCloudFrontのポリシーを参照）］
  # Managed-SimpleCORS: シンプルなCORSリクエスト対応のポリシー。
  #   CORS対応が必要だが、OPTIONSなどのプリフライトリクエストは不要なケース向け（例：画像, フォント, スクリプトの読み込み）。
  # Managed-CORS-and-SecurityHeadersPolicy: SimpleCORSに加え、セキュリティ強化のレスポンスヘッダーも自動追加のポリシー。
  #   CORS対応が必要だが、OPTIONSなどのプリフライトリクエストは不要で、セキュリティ対応もしたいケースで利用する。
  # Managed-CORS-With-Preflight: OPTIONSプリフライトリクエストを含むすべてのCORSリクエストに対応のポリシー。
  #   複雑なCORSリクエスト（例：POST + Authorizationヘッダーなど）に対応したいケースで利用する。
  # Managed-CORS-with-preflight-and-SecurityHeadersPolicy: CORS-With-Preflightに加え、セキュリティ強化のレスポンスヘッダーも自動追加のポリシー。
  #   複雑なCORSリクエスト（例：POST + Authorizationヘッダーなど）に対応しつつ、セキュリティ強化もしたいケースで利用する。
  # Managed-SecurityHeadersPolicy: セキュリティ強化のレスポンスヘッダーを追加したポリシー。
  #   CORS対応は不要だが、静的なサイトでセキュリティ強化のレスポンスヘッダーを追加したい場合に利用する。
  name = "Managed-SimpleCORS"
}

# API Gateway用のレスポンスヘッダーポリシー（CORS対応する場合に必要）
data "aws_cloudfront_response_headers_policy" "CORSWithPreflightAndSecurityHeadersPolicy" {
  # レスポンスヘッダーポリシー名
  #［AWSマネージドポリシーの一覧（詳細はAWSコンソールからCloudFrontのポリシーを参照）］
  # Managed-SimpleCORS: シンプルなCORSリクエスト対応のポリシー。
  #   CORS対応が必要だが、OPTIONSなどのプリフライトリクエストは不要なケース向け（例：画像, フォント, スクリプトの読み込み）。
  # Managed-CORS-and-SecurityHeadersPolicy: SimpleCORSに加え、セキュリティ強化のレスポンスヘッダーも自動追加のポリシー。
  #   CORS対応が必要だが、OPTIONSなどのプリフライトリクエストは不要で、セキュリティ対応もしたいケースで利用する。
  # Managed-CORS-With-Preflight: OPTIONSプリフライトリクエストを含むすべてのCORSリクエストに対応のポリシー。
  #   複雑なCORSリクエスト（例：POST + Authorizationヘッダーなど）に対応したいケースで利用する。
  # Managed-CORS-with-preflight-and-SecurityHeadersPolicy: CORS-With-Preflightに加え、セキュリティ強化のレスポンスヘッダーも自動追加のポリシー。
  #   複雑なCORSリクエスト（例：POST + Authorizationヘッダーなど）に対応しつつ、セキュリティ強化もしたいケースで利用する。
  # Managed-SecurityHeadersPolicy: セキュリティ強化のレスポンスヘッダーを追加したポリシー。
  #   CORS対応は不要だが、静的なサイトでセキュリティ強化のレスポンスヘッダーを追加したい場合に利用する。
  name = "Managed-CORS-With-Preflight"
}

# S3へのOACの作成
resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = "s3-cloudfront-origin-access-control"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# LambdaへのOACの作成
resource "aws_cloudfront_origin_access_control" "lambda" {
  name                              = "lambda-cloudfront-origin-access-control"
  origin_access_control_origin_type = "lambda"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Cloudfront distributionのURL出力
output "cloudfront_distribution_url" {
  description = "CloudFront distribution URL"
  value       = "https://${aws_cloudfront_distribution.main.domain_name}/"
}
