#============================================================
# Cloud Source Repositories
#============================================================

# リポジトリの作成
resource "google_sourcerepo_repository" "repo" {
  depends_on = [google_project_service.apis]
  # リポジトリ名
  name = var.project_id
}
