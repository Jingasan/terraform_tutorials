#============================================================
# Google Cloud APIの有効化
#============================================================

# 有効化するAPIの一覧
locals {
  services = {
    "Google Cloud Memorystore for Redis API" : "redis.googleapis.com",
    "Artifact Registry API" : "artifactregistry.googleapis.com",
    "Backup for GKE API" : "gkebackup.googleapis.com",
    "BigQuery API" : "bigquery.googleapis.com",
    "BigQuery Migration API" : "bigquerymigration.googleapis.com",
    "BigQuery Storage API" : "bigquerystorage.googleapis.com",
    "Cloud Autoscaling API" : "autoscaling.googleapis.com",
    "Cloud Deployment Manager V2 API" : "deploymentmanager.googleapis.com",
    "Cloud DNS API" : "dns.googleapis.com",
    "Cloud Logging API" : "logging.googleapis.com",
    "Cloud Monitoring API" : "monitoring.googleapis.com",
    "Cloud OS Login API" : "oslogin.googleapis.com",
    "Cloud Pub/Sub API" : "pubsub.googleapis.com",
    "Cloud Storage" : "storage-component.googleapis.com",
    "Cloud Trace API" : "cloudtrace.googleapis.com",
    "Compute Engine API" : "compute.googleapis.com",
    "Container File System API" : "containerfilesystem.googleapis.com",
    "Container Registry API" : "containerregistry.googleapis.com",
    "Google Cloud Storage JSON API" : "storage-api.googleapis.com",
    "IAM Service Account Credentials API" : "iamcredentials.googleapis.com",
    "Identity and Access Management (IAM) API" : "iam.googleapis.com",
    "Kubernetes Engine API" : "container.googleapis.com",
    "Network Connectivity API" : "networkconnectivity.googleapis.com",
    "Service Networking API" : "servicenetworking.googleapis.com",
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
