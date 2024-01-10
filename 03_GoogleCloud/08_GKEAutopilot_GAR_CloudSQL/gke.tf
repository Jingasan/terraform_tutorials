#============================================================
# GKE
#============================================================

# Autopilotモードのクラスターの作成
resource "google_container_cluster" "cluster" {
  depends_on = [google_project_service.apis]
  # クラスター名
  name = var.project_id
  # リージョン
  location = var.region
  # Autopilotモードの有効化(true:Autopilot, false:Standard)
  enable_autopilot = true
  # クラスターを所属させるVPC
  network = google_compute_network.vpc.id
  # クラスターを所属させるサブネット
  subnetwork = google_compute_subnetwork.subnet.id
  # ロギングサービス
  logging_service = "logging.googleapis.com/kubernetes"
  # モニタリングサービス
  monitoring_service = "monitoring.googleapis.com/kubernetes"
  # 削除保護(true:保護)
  deletion_protection = false
  # 説明文
  description = var.project_id
  # タグ
  resource_labels = {
    name = var.project_id
  }
}
