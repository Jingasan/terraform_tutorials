#============================================================
# Certificate Manager
#============================================================

# GoogleマネージドSSL証明書の作成
resource "google_compute_managed_ssl_certificate" "ssl" {
  depends_on = [google_project_service.apis]
  # プロバイダ
  provider = google-beta
  # 証明書名
  name = var.project_id
  # プロジェクトID
  project = var.project_id
  # Googleマネージド証明書の設定
  managed {
    # ドメイン
    domains = [var.certificate_manager_domain]
  }
  # 説明文
  description = var.project_id
}
