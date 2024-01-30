#============================================================
# Artifact Registry
#============================================================

# リポジトリの作成
resource "google_artifact_registry_repository" "container_repository" {
  depends_on = [google_project_service.apis]
  # リポジトリ名
  repository_id = var.gar_image_name
  # 形式(docker/npm/python/go/maven/apt/yum/kfp)
  format = "docker"
  # ロケーション
  location = var.region
  # モード(STANDARD_REPOSITORY/REMOTE_REPOSITORY/VIRTUAL_REPOSITORY)
  mode = "STANDARD_REPOSITORY"
  # Dockerリポジトリ固有の設定
  docker_config {
    # 不変のイメージタグ(true:有効/false:無効(default))
    immutable_tags = false
  }
  # リポジトリの説明文
  description = var.project_id
  # ラベル
  labels = {
    name = var.project_id
  }
}
