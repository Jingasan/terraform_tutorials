#============================================================
# 環境変数の定義（terraform.tfvarsの変数値を受け取る）
#============================================================
# プロジェクトID
variable "project_id" {}
# リージョン
variable "region" {}
#============================================================
# Memorystore Redis
#============================================================
# Redisバージョン
variable "gms_redis_version" {}
# ティア
variable "gms_redis_tier" {}
# 実メモリ容量(GB)
# ティアがBASICの場合は最小値:1,最大値:300
# ティアがSTANDARDの場合は最小値:5,最大値:300
variable "gms_redis_memory_size_gb" {}
# 読み取りアクセス用のレプリカノード数
# ティアがSTANDARDの場合のみ、1-5で指定可能(default:2)
variable "gms_redis_replica_count" {}
