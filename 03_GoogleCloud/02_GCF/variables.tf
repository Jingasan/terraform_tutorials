#============================================================
# 環境変数の定義（terraform.tfvarsの変数値を受け取る）
#============================================================
# プロジェクトID
variable "project_id" {}
# リージョン
variable "region" {}
#============================================================
# Cloud Storage
#============================================================
# ストレージクラス
variable "gcs_storage_class" {}
#============================================================
# Cloud Functions
#============================================================
# ランタイム
variable "gcf_runtime" {}
# 最大vCPU数 default:最大メモリ量から算出される
variable "gcf_available_cpu" {}
# 最大メモリ量 default:256M
variable "gcf_available_memory" {}
# 関数のタイムアウト時間[sec] default:60
variable "gcf_timeout_seconds" {}
# 最大インスタンス数 default:100
variable "gcf_max_instance_count" {}
# 最小インスタンス数 default:0
variable "gcf_min_instance_count" {}
# インスタンスあたりの最大同時リクエスト数 default:1
variable "gcf_max_instance_request_concurrency" {}
