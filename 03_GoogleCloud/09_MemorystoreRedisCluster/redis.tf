#============================================================
# Memorystore Redis Cluster
#============================================================

# Redisクラスターの作成
resource "google_redis_cluster" "cluster" {
  depends_on = [google_project_service.apis, google_network_connectivity_service_connection_policy.default]
  # クラスター名
  name = var.project_id
  # 作成先のリージョン
  region = var.region
  # シャード数
  shard_count = 3
  # レプリカノード数
  replica_count = var.gms_redis_replica_count
  # プライベートサービス接続の設定
  psc_configs {
    # ネットワークの指定
    network = google_compute_network.producer_net.id
  }
  # IAM AUTHの有効化
  # AUTH_MODE_UNSPECIFIED/AUTH_MODE_IAM_AUTH/AUTH_MODE_DISABLED
  authorization_mode = "AUTH_MODE_DISABLED"
  # 転送中のTLS暗号化の有効化
  # TRANSIT_ENCRYPTION_MODE_UNSPECIFIED/TRANSIT_ENCRYPTION_MODE_DISABLED/TRANSIT_ENCRYPTION_MODE_SERVER_AUTHENTICATION
  transit_encryption_mode = "TRANSIT_ENCRYPTION_MODE_DISABLED"
  # Redisクラスターの削除の禁止(true:削除を禁止/false:削除を許可)
  lifecycle {
    prevent_destroy = false
  }
}

# サービス接続ポリシーの作成
resource "google_network_connectivity_service_connection_policy" "default" {
  depends_on = [google_project_service.apis]
  # サービス接続ポリシー名称
  name = var.project_id
  # 作成先のリージョン
  location = var.region
  # サービスクラス
  service_class = "gcp-memorystore-redis"
  # ターゲットのネットワーク
  network = google_compute_network.producer_net.id
  # プライベートサービス接続(PSC)の設定
  psc_config {
    # PSCのアドレスとこのポリシーのPSC接続の上限を割り当てるためのサブネットワーク
    subnetworks = [google_compute_subnetwork.producer_subnet.id]
  }
  # 説明文
  description = "${var.project_id} basic service connection policy"
}

# VPCの作成
resource "google_compute_network" "producer_net" {
  depends_on = [google_project_service.apis]
  # VPC名
  name = var.project_id
  # サブネットの自動生成(true:自動生成)
  auto_create_subnetworks = false
  # 説明文
  description = var.project_id
}

# サブネットの作成
resource "google_compute_subnetwork" "producer_subnet" {
  depends_on = [google_project_service.apis]
  # サブネット名
  name = var.project_id
  # サブネットのリージョン
  region = var.region
  # IPアドレスの範囲
  ip_cidr_range = "10.0.0.248/29"
  # VPC
  network = google_compute_network.producer_net.id
  # 説明文
  description = var.project_id
}
