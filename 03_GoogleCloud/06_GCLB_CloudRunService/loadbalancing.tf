#============================================================
# Google Cloud Load Balancing
#============================================================

# アプリケーションロードバランサー(HTTPS)の作成
resource "google_compute_target_https_proxy" "https" {
  depends_on = [google_project_service.apis]
  # アプリケーションロードバランサー名
  name = "${var.project_id}-https"
  # ルーティングルールの定義の指定
  url_map = google_compute_url_map.https.id
  # 証明書
  ssl_certificates = [google_compute_managed_ssl_certificate.ssl.id]
  # 説明文
  description = var.project_id
}
# アプリケーションロードバランサー(HTTP)の作成
resource "google_compute_target_http_proxy" "http" {
  depends_on = [google_project_service.apis]
  # アプリケーションロードバランサー名
  name = "${var.project_id}-http"
  # ルーティングルールの定義の指定
  url_map = google_compute_url_map.http.id
  # 説明文
  description = var.project_id
}

# 転送ルールの作成
resource "google_compute_global_forwarding_rule" "https" {
  depends_on = [google_project_service.apis]
  # 転送ルール名
  name = "${var.project_id}-https"
  # IPアドレス
  ip_address = google_compute_global_address.default.id
  # ポート
  port_range = "443"
  # ターゲットのロードバランサー
  target = google_compute_target_https_proxy.https.id
  # ラベル
  labels = {
    name = var.project_id
  }
  # 説明文
  description = var.project_id
}
resource "google_compute_global_forwarding_rule" "http" {
  depends_on = [google_project_service.apis]
  # 転送ルール名
  name = "${var.project_id}-http"
  # IPアドレス
  ip_address = google_compute_global_address.default.id
  # ポート
  port_range = "80"
  # ターゲットのロードバランサー
  target = google_compute_target_http_proxy.http.id
  # ラベル
  labels = {
    name = var.project_id
  }
  # 説明文
  description = var.project_id
}

# バックエンドサービスの作成
resource "google_compute_backend_service" "backend" {
  depends_on = [google_project_service.apis]
  # バックエンドサービス名称
  name = var.project_id
  # プロトコル
  protocol = "HTTP"
  # 名前付きポート
  port_name = "http"
  # タイムアウト(秒)：1-86400の範囲で指定可能(default:30)
  timeout_sec = 30
  # バックエンド
  backend {
    # バックエンドにCloud RunのRegional Network Endpoint Groupを指定
    group = google_compute_region_network_endpoint_group.cloud_run.id
  }
  # Cloud CDNのキャッシュ設定
  cdn_policy {
    # キャッシュモード
    # CACHE_ALL_STATIC(default): 静的コンテンツをキャッシュする
    # USE_ORIGIN_HEADERS: Cache-Controlヘッダーに基づいて送信元の設定を使用する
    # FORCE_CACHE_ALL: すべてのコンテンツを強制的にキャッシュする
    cache_mode = "CACHE_ALL_STATIC"
    # クライアントTTL(分) default:60
    client_ttl = 60
    # デフォルトTTL(分)
    default_ttl = 60
    # 最大TTL(分)
    max_ttl = 1440
    # Signed URLの最大キャッシュ時間(秒)
    signed_url_cache_max_age_sec = 3600
  }
  # Cloud Loggingのログ出力設定
  log_config {
    # ロギングの有効化(true:有効)
    enable = true
  }
  # 説明文
  description = var.project_id
}

# サーバーレスネットワークエンドポイントグループ(NEG)の作成
resource "google_compute_region_network_endpoint_group" "cloud_run" {
  depends_on = [google_project_service.apis]
  # NEG名
  name = var.project_id
  # リージョン
  region = var.region
  # ネットワークエンドポイントのタイプ (SERVERLESS/PRIVATE_SERVICE_CONNECT)
  # SERVERLESS: Cloud Run/Cloud Functions/App Engineの場合に選択する
  network_endpoint_type = "SERVERLESS"
  # 紐付けるCloud Runのサービスの指定
  cloud_run {
    service = google_cloud_run_v2_service.service.name
  }
  # 説明文
  description = var.project_id
}

# ルーティングルールの作成
resource "google_compute_url_map" "https" {
  depends_on = [google_project_service.apis]
  # ルーティングルール名
  name = "${var.project_id}-https"
  # デフォルト
  default_service = google_compute_backend_service.backend.self_link
  # 説明文
  description = var.project_id
}

# ルーティングルールの作成(http→httpsリダイレクトの設定)
resource "google_compute_url_map" "http" {
  depends_on = [google_project_service.apis]
  # ルーティングルール名
  name = "${var.project_id}-http"
  # default_url_redirectを指定する場合は、default_serviceは指定してはいけない
  default_url_redirect {
    # クエリの無効化(true:無効/false:無効化しない)
    strip_query = false
    # httpsリダイレクト(true:有効)
    https_redirect = true
  }
  # 説明文
  description = var.project_id
}
