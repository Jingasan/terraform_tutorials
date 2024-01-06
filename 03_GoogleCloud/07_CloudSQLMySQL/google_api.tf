#============================================================
# Google Cloud APIの有効化
#============================================================

# 有効化するAPIの一覧
locals {
  services = {
    "Cloud OS Login API" : "oslogin.googleapis.com",
    "Compute Engine API" : "compute.googleapis.com",
    "Cloud SQL Admin API" : "sqladmin.googleapis.com",
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
