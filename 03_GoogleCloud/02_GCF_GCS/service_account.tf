#============================================================
# Service Account
#============================================================

# サービスアカウントの作成
# GCSでPresignedURLを発行するためのサービスアカウントを作成する
resource "google_service_account" "gcs" {
  # サービスアカウントID
  account_id = "gcs-presignedurl"
  # サービスアカウントの名前
  display_name = "GCS PresignedURL"
  # サービスアカウントの説明文
  description = "Service Account for publishing GCS PresignedURL"
}

# サービスアカウントに権限(ロール)を割り当て
resource "google_project_iam_member" "gcs" {
  # プロジェクトID
  project = var.project_id
  # ロール割り当て先のユーザー：サービスアカウントを指定
  member = "serviceAccount:${google_service_account.gcs.email}"
  # 割り当てるロール：ストレージ管理者
  role = "roles/storage.objectAdmin"
}

# アカウントキーの作成
resource "google_service_account_key" "key" {
  # アカウントキーを作成するサービスアカウントのID
  service_account_id = google_service_account.gcs.name
}

