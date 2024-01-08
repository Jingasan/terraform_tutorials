#============================================================
# Network
#============================================================

# VPCの作成
resource "google_compute_network" "vpc" {
  depends_on = [google_project_service.apis]
  # VPC名
  name = var.project_id
  # サブネットの自動生成(true:自動生成)
  auto_create_subnetworks = false
  # 説明文
  description = var.project_id
}

# サブネットの作成
resource "google_compute_subnetwork" "subnet" {
  depends_on = [google_project_service.apis]
  # サブネット名
  name = var.project_id
  # サブネットのリージョン
  region = var.region
  # IPアドレスの範囲
  ip_cidr_range = "192.168.1.0/24"
  # VPC
  network = google_compute_network.vpc.id
  # 説明文
  description = var.project_id
}

# 外部静的IPアドレスの予約
resource "google_compute_global_address" "default" {
  depends_on = [google_project_service.apis]
  # 外部静的IPアドレスの名前
  name = var.project_id
  # IPバージョン(IPV4(default)/IPV6)
  ip_version = "IPV4"
  # タイプ(INTERNAL:リージョン内部ネットワークIPアドレスの範囲/EXTERNAL(default):単一のグローバルIPアドレス)
  address_type = "EXTERNAL"
  # 説明文
  description = var.project_id
}
