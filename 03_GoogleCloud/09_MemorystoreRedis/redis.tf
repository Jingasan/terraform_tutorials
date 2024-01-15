#============================================================
# Memorystore Redis
#============================================================

# 単一Redisの作成
resource "google_redis_instance" "instance" {
  depends_on = [google_project_service.apis]
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
}
