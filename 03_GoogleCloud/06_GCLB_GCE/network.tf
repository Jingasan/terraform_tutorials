#============================================================
# Network
#============================================================

# VPCネットワークの作成
resource "google_compute_network" "vpc" {
  depends_on = [google_project_service.apis]
  # VPCネットワーク名
  name = var.project_id
  # サブネットの自動生成(true:自動生成/false)
  auto_create_subnetworks = false
  # MTU
  mtu = 1460
}

# サブネットの作成
resource "google_compute_subnetwork" "subnet" {
  depends_on = [google_project_service.apis]
  # サブネット名
  name = var.project_id
  # リージョン
  region = var.region
  # サブネットで使用する内部IPアドレスの範囲
  network       = google_compute_network.vpc.id
  ip_cidr_range = "10.0.1.0/24"
  # CloudLogggingにFlowLogを出力する設定
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# 外部静的IPアドレスの予約
# 外部静的IPアドレスは外部HTTP(S)ロードバランサーに設定する。
# また、Cloud DNSにドメインと登録し、ドメインと対応付ける。
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

# 外部静的IPアドレスの表示
output "ip_address" {
  description = "ip_address"
  value       = google_compute_global_address.default.address
}
