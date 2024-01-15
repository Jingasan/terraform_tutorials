#============================================================
# Memorystore Redis
#============================================================

# 単一Redisの作成
resource "google_redis_instance" "instance" {
  depends_on = [google_project_service.apis, google_service_networking_connection.default]
  # インスタンスID
  name = var.project_id
  # 表示名
  display_name = var.project_id
  # Redisのバージョン
  redis_version = var.gms_redis_version
  # リージョン
  region = var.region
  # ティア(BASIC/STANDARD)
  tier = var.gms_redis_tier
  # 実メモリ容量(GB)
  # ティアがBASICの場合は最小値:1,最大値:300
  # ティアがSTANDARDの場合は最小値:5,最大値:300
  memory_size_gb = var.gms_redis_memory_size_gb
  # 読み取りアクセス用のレプリカノード数
  # ティアがSTANDARDの場合のみ、1-5で指定可能(default:2)
  replica_count = var.gms_redis_replica_count
  # 接続モード(DIRECT_PEERING(default)/PRIVATE_SERVICE_ACCESS)
  connect_mode = "PRIVATE_SERVICE_ACCESS"
  # Redisインスタンスを接続するネットワークの指定
  authorized_network = google_compute_network.vpc.id
  # Redisの削除の禁止(true:削除を禁止/false:削除を許可)
  lifecycle {
    prevent_destroy = false
  }
}
