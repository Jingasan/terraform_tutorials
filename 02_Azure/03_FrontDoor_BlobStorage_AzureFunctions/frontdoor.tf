#============================================================
# Front Door
#============================================================

# FrontDoorの作成
resource "azurerm_cdn_frontdoor_profile" "frontdoor" {
  # FrontDoor名
  name = var.project_name
  # リソースグループ
  resource_group_name = azurerm_resource_group.rg.name
  # 機能プラン
  sku_name = "Standard_AzureFrontDoor"
  # タグ
  tags = {
    Name = var.project_name
  }
}

# FrontDoorエンドポイントの作成
resource "azurerm_cdn_frontdoor_endpoint" "endpoint" {
  # エンドポイント名
  name = var.project_name
  # エンドポイントの設定先のFrontDoorID
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoor.id
  # 有効／無効
  enabled = true
  # タグ
  tags = {
    Name = var.project_name
  }
}

# Blob Storageのルートの追加
resource "azurerm_cdn_frontdoor_route" "blob_route" {
  # ルート名
  name = "default-route"
  # エンドポイント
  cdn_frontdoor_endpoint_id = azurerm_cdn_frontdoor_endpoint.endpoint.id
  # ルートの有効化
  link_to_default_domain = true
  # 受け入れ済みのプロトコル
  supported_protocols = ["Http", "Https"]
  # 一致するパターン
  patterns_to_match = ["/*"]
  # 転送プロトコル
  forwarding_protocol = "HttpsOnly"
  # HTTPSリダイレクト設定
  https_redirect_enabled = true
  # 配信元グループID
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.blob_origin_group.id
  # 配信元ID
  cdn_frontdoor_origin_ids = [azurerm_cdn_frontdoor_origin.blob_origin.id]
  # キャッシュ
  cache {
    # クエリ文字列のキャッシュ動作
    # IgnoreQueryString(Default)/IgnoreSpecifiedQueryStrings/IncludeSpecifiedQueryStrings/UseQueryString
    query_string_caching_behavior = "UseQueryString" # クエリ文字列を使用する
    # 配信コンテンツを圧縮するか (true/false)
    compression_enabled = true
    # 圧縮対象のMIMEタイプ
    content_types_to_compress = [
      "application/javascript",
      "application/json",
      "application/xml",
      "application/xml+rss",
      "application/x-javascript",
      "image/svg+xml",
      "text/css",
      "text/csv",
      "text/html",
      "text/javascript",
      "text/js",
      "text/plain",
      "text/xml",
      "text/x-script",
      "text/x-component"
    ]
  }
}

# Blob Storageの配信元グループの作成
resource "azurerm_cdn_frontdoor_origin_group" "blob_origin_group" {
  # 配信元グループ名
  name = "default-origin-group"
  # 配信元グループの設定先のFrontDoorID
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoor.id
  # セッションアフィニティの有効化
  session_affinity_enabled = true
  # 正常性プローブ
  # 有効にすると、FrontDoorは各配信元に定期的なリクエストを送信し、
  # それらの近接性と正常性を判断し、負荷分散する。
  health_probe {
    # パス
    path = "/"
    # プロトコル
    protocol = "Https"
    # プローブメソッド
    request_type = "HEAD"
    # 間隔(秒)
    interval_in_seconds = 100
  }
  # 負荷分散
  load_balancing {
    # サンプルサイズ
    sample_size = 4
    # 必要な成功したサンプル
    successful_samples_required = 3
    # 待機時間感度（ミリ秒）
    additional_latency_in_milliseconds = 50
  }
}

# Blob Storageの配信元の追加
resource "azurerm_cdn_frontdoor_origin" "blob_origin" {
  # 配信元名（オリジン名）
  name = "default-origin"
  # 配信元の設定先のFrontDoorID
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.blob_origin_group.id
  # この配信元を有効にするか（true/false）
  enabled = true
  # ホスト名
  host_name = azurerm_storage_account.blob.primary_blob_host
  # 配信元のホストヘッダー
  origin_host_header = azurerm_storage_account.blob.primary_blob_host
  # 証明書のサブジェクト名の検証
  certificate_name_check_enabled = true
  # HTTPポート
  http_port = 80
  # HTTPSポート
  https_port = 443
  # 優先順位
  priority = 1
  # 重み
  weight = 1000
}

# APIのルートの追加
resource "azurerm_cdn_frontdoor_route" "api_route" {
  # ルート名
  name = "api-route"
  # エンドポイント
  cdn_frontdoor_endpoint_id = azurerm_cdn_frontdoor_endpoint.endpoint.id
  # ルートの有効化
  link_to_default_domain = true
  # 受け入れ済みのプロトコル
  supported_protocols = ["Http", "Https"]
  # 一致するパターン
  patterns_to_match = ["/api/*"]
  # 転送プロトコル
  forwarding_protocol = "MatchRequest"
  # HTTPSリダイレクト設定
  https_redirect_enabled = true
  # 配信元グループID
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.api_origin_group.id
  # 配信元ID
  cdn_frontdoor_origin_ids = [azurerm_cdn_frontdoor_origin.api_origin.id]
  # キャッシュ
  cache {
    # クエリ文字列のキャッシュ動作
    # IgnoreQueryString(Default)/IgnoreSpecifiedQueryStrings/IncludeSpecifiedQueryStrings/UseQueryString
    query_string_caching_behavior = "UseQueryString" # クエリ文字列を使用する
    # 配信コンテンツを圧縮するか (true/false)
    compression_enabled = true
    # 圧縮対象のMIMEタイプ
    content_types_to_compress = [
      "application/javascript",
      "application/json",
      "application/xml",
      "application/xml+rss",
      "application/x-javascript",
      "image/svg+xml",
      "text/css",
      "text/csv",
      "text/html",
      "text/javascript",
      "text/js",
      "text/plain",
      "text/xml",
      "text/x-script",
      "text/x-component"
    ]
  }
}

# APIの配信元グループの作成
resource "azurerm_cdn_frontdoor_origin_group" "api_origin_group" {
  # 配信元グループ名
  name = "api-origin-group"
  # 配信元グループの設定先のFrontDoorID
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoor.id
  # セッションアフィニティの有効化
  session_affinity_enabled = true
  # 正常性プローブ
  # 有効にすると、FrontDoorは各配信元に定期的なリクエストを送信し、
  # それらの近接性と正常性を判断し、負荷分散する。
  health_probe {
    # パス
    path = "/"
    # プロトコル
    protocol = "Https"
    # プローブメソッド
    request_type = "HEAD"
    # 間隔(秒)
    interval_in_seconds = 100
  }
  # 負荷分散
  load_balancing {
    # サンプルサイズ
    sample_size = 4
    # 必要な成功したサンプル
    successful_samples_required = 3
    # 待機時間感度（ミリ秒）
    additional_latency_in_milliseconds = 50
  }
}

# APIの配信元の追加
resource "azurerm_cdn_frontdoor_origin" "api_origin" {
  # 配信元名（オリジン名）
  name = "api-origin"
  # 配信元の設定先のFrontDoorID
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.api_origin_group.id
  # この配信元を有効にするか（true/false）
  enabled = true
  # ホスト名
  host_name = azurerm_linux_function_app.functions.default_hostname
  # 配信元のホストヘッダー
  origin_host_header = azurerm_linux_function_app.functions.default_hostname
  # 証明書のサブジェクト名の検証
  certificate_name_check_enabled = true
  # HTTPポート
  http_port = 80
  # HTTPSポート
  https_port = 443
  # 優先順位
  priority = 1
  # 重み
  weight = 1000
}

# FrontDoor URLの表示
output "frontdoor_url" {
  description = "FrontDoor URL"
  value       = azurerm_cdn_frontdoor_endpoint.endpoint.host_name
}

# WebページURLの表示
output "webpage_url" {
  description = "Web Page URL"
  value       = "https://${azurerm_cdn_frontdoor_endpoint.endpoint.host_name}/${azurerm_storage_container.blob.name}/index.html"
}

# API URLの表示
output "api_url" {
  description = "API URL"
  value       = "https://${azurerm_cdn_frontdoor_endpoint.endpoint.host_name}/api/blob"
}
