#============================================================
# Google Cloud Load Balancing
#============================================================

# 外部静的IPアドレスの予約
resource "google_compute_global_address" "default" {
  depends_on = [google_project_service.apis]
  # 外部静的IPアドレスの名前
  name = var.project_id
  # IPバージョン(IPV4(default)/IPV6)
  ip_version = "IPV4"
  # タイプ(INTERNAL:リージョン内部ネットワークIPアドレスの範囲/EXTERNAL(default):単一のグローバルIPアドレス)
  address_type = "EXTERNAL"
  # 説明文
  description = var.project_id
}

# アプリケーションロードバランサー(HTTPS)の作成
resource "google_compute_target_https_proxy" "https" {
  depends_on = [google_project_service.apis]
  # アプリケーションロードバランサー名
  name = "${var.project_id}-https"
  # ルーティングルールの定義の指定
  url_map = google_compute_url_map.https.id
  # 証明書
  ssl_certificates = [google_compute_managed_ssl_certificate.ssl.id]
  # HTTPキープアライブタイムアウト(default:610[sec])
  http_keep_alive_timeout_sec = 610
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
  # HTTPキープアライブタイムアウト(default:610[sec])
  http_keep_alive_timeout_sec = 610
  # 説明文
  description = var.project_id
}

# 転送ルールの作成
resource "google_compute_global_forwarding_rule" "https" {
  depends_on = [google_project_service.apis]
  # 転送ルール名
  name = "${var.project_id}-https"
  # ロードバランサーのスキーム(EXTERNAL(default)/EXTERNAL_MANAGED/INTERNAL_MANAGED/INTERNAL_SELF_MANAGED)
  load_balancing_scheme = "EXTERNAL_MANAGED"
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
}
resource "google_compute_global_forwarding_rule" "http" {
  depends_on = [google_project_service.apis]
  # 転送ルール名
  name = "${var.project_id}-http"
  # ロードバランサーのスキーム(EXTERNAL(default)/EXTERNAL_MANAGED/INTERNAL_MANAGED/INTERNAL_SELF_MANAGED)
  load_balancing_scheme = "EXTERNAL_MANAGED"
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
}

# ロードバランサ―のバックエンドバケットの作成
resource "google_compute_backend_bucket" "backend" {
  depends_on = [google_project_service.apis]
  # バックエンド名
  name = var.project_id
  # バックエンドに指定するGCSのバケット名
  bucket_name = google_storage_bucket.bucket.name
  # Cloud CDNを有効化
  enable_cdn = true
  # Cloud CDNのキャッシュ設定
  cdn_policy {
    # キャッシュモード
    # CACHE_ALL_STATIC(default): 静的コンテンツをキャッシュする(推奨)
    # USE_ORIGIN_HEADERS: Cache-Controlヘッダーに基づいて送信元の設定を使用する
    # FORCE_CACHE_ALL: すべてのコンテンツを強制的にキャッシュする
    cache_mode = "CACHE_ALL_STATIC"
    # クライアント有効期限(秒)(default:1時間)
    client_ttl = 3600
    # デフォルトの有効期限(秒)(default:1時間)
    default_ttl = 3600
    # 最大有効期限(秒)(default:1時間)
    max_ttl = 3600
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
  default_service = google_compute_backend_bucket.backend.id
  # ホストのルール
  host_rule {
    # ホスト
    hosts = [var.certificate_manager_domain]
    # 対応付けるpath_matcherの指定
    path_matcher = var.project_id
  }
  # path matcher
  path_matcher {
    # path_matcharの名前
    name = var.project_id
    # デフォルトのバックエンドサービス
    default_service = google_compute_backend_bucket.backend.id
    # パスのルール
    path_rule {
      # ルーティング対象のURLパス
      paths = ["/*"]
      # バックエンドのサービスを指定：GCSのバケットをバックエンドに指定
      service = google_compute_backend_bucket.backend.id
    }
  }
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
}

# ドメイン名の表示
output "domain" {
  description = "domain"
  value       = var.certificate_manager_domain
}

# 外部静的IPアドレスの表示
output "ip_address" {
  description = "ip_address"
  value       = google_compute_global_address.default.address
}
