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
  # ティア(BASIC/STANDARD)
  tier = var.gms_redis_tier
  # 実メモリ容量(GB)
  # ティアがBASICの場合は最小値:1,最大値:300
  # ティアがSTANDARDの場合は最小値:5,最大値:300
  memory_size_gb = 1
  # リージョン
  region = var.region
  # 読み取りアクセス用のレプリカノード数
  # ティアがSTANDARDの場合のみ、1-5で指定可能(default:2)
  replica_count = 0
  # Redisのバージョン
  redis_version = var.gms_redis_version
}
