#============================================================
# Service Account
#============================================================

# GKEからGCSを操作するためのサービスアカウントの作成
resource "google_service_account" "gcs" {
  depends_on = [google_project_service.apis]
  # サービスアカウントID
  account_id = "gcs-service-account"
  # サービスアカウントの名前
  display_name = "Service Account for GCS"
  # サービスアカウントの説明文
  description = "Service Account for GCS"
}

# サービスアカウントに権限(ロール)を割り当て
resource "google_project_iam_member" "gcs" {
  depends_on = [google_project_service.apis]
  # プロジェクトID
  project = var.project_id
  # ロール割り当て先のユーザー：サービスアカウントを指定
  member = "serviceAccount:${google_service_account.gcs.email}"
  # 割り当てるロール：ストレージ管理者(バケットとオブジェクトのすべてを管理する最上位の権限)
  role = "roles/storage.admin"
}

# アカウントキーの作成
resource "google_service_account_key" "key" {
  depends_on = [google_project_service.apis]
  # アカウントキーを作成するサービスアカウントのID
  service_account_id = google_service_account.gcs.name
}

# GCSアクセスのためのCredentialファイルの出力
resource "local_file" "credential" {
  # 出力先
  filename = "service_account_key.json"
  # 出力ファイルのパーミッション
  file_permission = "0644"
  # ファイル内容
  content = base64decode(google_service_account_key.key.private_key)
}
