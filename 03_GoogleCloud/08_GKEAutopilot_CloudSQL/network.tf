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

# プライベートIPアドレスの予約
# ユーザー定義のVPC内のGKEからCloudSQLに対してプライベート接続するために取得する。
resource "google_compute_global_address" "private_ip_address" {
  depends_on = [google_project_service.apis]
  # 名称
  name = "${var.project_id}-private-ip"
  # IPアドレスを予約する対象のネットワーク
  network = google_compute_network.vpc.id
  # 利用目的(VPC_PEERING/PRIVATE_SERVICE_CONNECT)
  purpose = "VPC_PEERING"
  # 予約IPアドレスの種類(EXTERNAL/INTERNAL)
  address_type = "INTERNAL"
  # 予約IPアドレスのプレフィックス長
  prefix_length = 16
  # 説明文
  description = var.project_id
}

# プライベートVPC接続の作成
# GCPでは、プライベートIPを持つCloudSQLはユーザーが定義したVPCではなく、
# Googleが管理するService Provider VPCに作成される。
# そのため、ユーザー定義のVPC内のGKEからCloudSQLに対してプライベートIPで通信する場合、
# プライベートVPC接続を作成し、接続経路を用意する必要がある。
resource "google_service_networking_connection" "default" {
  depends_on = [google_project_service.apis]
  # 削除時のエラー対策としてGoogleプロバイダーのバージョンを5ではなく、4を利用するように指定
  provider = google-beta
  # プロバイダーピアリングサービスの指定
  service = "servicenetworking.googleapis.com"
  # プライベートVPC接続の対象となるVPC
  network = google_compute_network.vpc.id
  # 予約されたプライベートIPアドレスの範囲
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}
