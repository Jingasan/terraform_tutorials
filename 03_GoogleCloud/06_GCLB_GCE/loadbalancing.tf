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

# ヘルスチェックの作成
resource "google_compute_health_check" "healthcheck" {
  depends_on = [google_project_service.apis]
  # ヘルスチェック名
  name = var.project_id
  # プロトコルとポート番号
  tcp_health_check {
    port = "80"
  }
  # ログの有効化(true:有効)
  log_config {
    enable = false
  }
  # タイムアウト(秒)
  timeout_sec = 5
  # チェック間隔(秒)
  check_interval_sec = 5
  # 正常閾値(回数)
  healthy_threshold = 2
  # 異常閾値(回数)
  unhealthy_threshold = 2
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
    # バックエンドにインスタンスグループを指定
    group = google_compute_instance_group.instancegroup.self_link
  }
  # ヘルスチェック
  health_checks = [google_compute_health_check.healthcheck.self_link]
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
}
