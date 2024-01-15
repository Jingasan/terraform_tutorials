#============================================================
# 環境変数の定義
#============================================================
# リージョン
region = "asia-northeast1"
#============================================================
# Memorystore Redis
#============================================================
# シャード数(最小値:3, 最大値:250(レプリカノード数に依存))
gms_redis_shard_count = 3
# レプリカノード数(最小値:0, 最大値:2)
gms_redis_replica_count = 0