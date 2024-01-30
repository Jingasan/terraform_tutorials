#============================================================
# Cloud Source Repositories
#============================================================

# リポジトリの作成
resource "google_sourcerepo_repository" "repo" {
  # リポジトリ名
  name = var.project_id
}
