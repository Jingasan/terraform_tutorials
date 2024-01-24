#============================================================
# Google Cloud APIの有効化
#============================================================

# 有効化するAPIの一覧
locals {
  services = {
    "Artifact Registry API" : "artifactregistry.googleapis.com",
    "Container Registry API" : "containerregistry.googleapis.com",
    "Cloud Run API" : "run.googleapis.com",
    "Cloud Storage" : "storage-component.googleapis.com",
    "Cloud Pub/Sub API" : "pubsub.googleapis.com",
    "Cloud Logging API" : "logging.googleapis.com",
    "Google Cloud Storage JSON API" : "storage-api.googleapis.com",
  }
}

# APIの有効化
resource "google_project_service" "apis" {
  # APIを有効化する対象のプロジェクトID
  project = var.project_id
  # 有効化するAPI群
  for_each = local.services
  service  = each.value
  # terraform destroy時にAPIを無効化する
  disable_dependent_services = true
  disable_on_destroy         = true
}
