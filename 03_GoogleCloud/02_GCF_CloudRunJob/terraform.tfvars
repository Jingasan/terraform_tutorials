#============================================================
# 環境変数の定義
#============================================================
# リージョン
region = "asia-northeast1"
#============================================================
# Cloud Storage
#============================================================
# ストレージクラス
gcs_storage_class = "Standard"
#============================================================
# Cloud Functions
#============================================================
# ランタイム
gcf_runtime = "nodejs18"
# 最大vCPU数 default:最大メモリ量から算出される
gcf_available_cpu = "0.2"
# 最大メモリ量 default:256M
gcf_available_memory = "256M"
# 関数のタイムアウト時間[sec] default:60
gcf_timeout_seconds = 60
# 最大インスタンス数 default:100
gcf_max_instance_count = 1
# 最小インスタンス数 default:0
gcf_min_instance_count = 0
# インスタンスあたりの最大同時リクエスト数 default:1
gcf_max_instance_request_concurrency = 1
#============================================================
# Cloud Run Job
#============================================================
# コンテナ名
gcr_container_name = "hello-world"
# コンテナイメージURL
gcr_image_url = "hello-world:latest"
