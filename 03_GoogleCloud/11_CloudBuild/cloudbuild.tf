#============================================================
# Cloud Build
#============================================================

# Cloud Buildの実行
resource "null_resource" "cloud_build" {
  # リポジトリ作成後に実行
  depends_on = [google_artifact_registry_repository.container_repository, google_service_account_iam_member.cloudbuild]
  # Cloud Buildの実行
  provisioner "local-exec" {
    command = "gcloud builds submit --config cloudbuild.yaml"
  }
}

# サービスアカウントの作成
resource "google_service_account" "cloud_build_service_account" {
  # アカウントID
  account_id = "${var.project_id}-service-account"
  # プロジェクトID
  project = var.project_id
  # 表示名
  display_name = "${var.project_id}-service-account"
  # 説明文
  description = "${var.project_id}-service-account"
}

# CloudBuildへのロールの割り当て
data "google_project" "project" {}
resource "google_service_account_iam_member" "cloudbuild" {
  # 割り当て対象のサービスアカウント
  service_account_id = google_service_account.cloud_build_service_account.id
  # 割り当てるロール
  role = "roles/iam.serviceAccountUser"
  # 割り当て対象のメンバー
  member = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}
