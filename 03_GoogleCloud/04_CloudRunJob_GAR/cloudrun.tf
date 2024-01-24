#============================================================
# Cloud Run Job
#============================================================

# ジョブの作成
resource "google_cloud_run_v2_job" "job" {
  depends_on = [google_project_service.apis, google_artifact_registry_repository.docker]
  # サービス名
  name = var.project_id
  # ロケーション
  location = var.region
  template {
    # ジョブの定義
    template {
      containers {
        # コンテナ名
        name = var.gar_image_name
        # リポジトリのイメージURL
        image = local.image_url
        # リソース関連の設定
        resources {
          limits = {
            # vCPUコア数上限
            cpu = "1"
            # メモリサイズ上限
            memory = "512Mi"
          }
        }
        # コンテナ起動時のコマンド
        command = []
        # コンテナ起動時の引数
        args = []
        # 環境変数
        env {
          name  = "ENV_NAME"
          value = "ENV_VALUE"
        }
      }
      # 最大リトライ回数
      max_retries = 3
    }
    # ラベル
    labels = {
      name = var.project_id
    }
    # アノテーション
    annotations = {
      name = var.project_id
    }
  }
  # ライフサイクルの設定
  lifecycle {
    # 無視する変更
    ignore_changes = [
      launch_stage,
    ]
  }
  # ラベル
  labels = {
    name = var.project_id
  }
  # アノテーション
  annotations = {
    name = var.project_id
  }
}

# ジョブの実行コマンドの表示
output "service_url" {
  description = "Job Execution Command"
  value       = "gcloud run jobs execute ${google_cloud_run_v2_job.job.name} --region=${google_cloud_run_v2_job.job.location}"
}
